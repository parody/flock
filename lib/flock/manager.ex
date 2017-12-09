defmodule Flock.Manager do
  @moduledoc """
  This is the core module of Flock.
  It is in charged of keeping track of alive processes, communicating changes
  to other nodes, and receiving notifications of processes ending and updates
  from another node
  """

  use GenServer

  alias Flock.{CRDT, Dispatch, Ring, WorkerSupervisor}

  require Logger

  defstruct [:active, :local]

  @type t :: %__MODULE__{active: Ring.t(), local: list()}

  @name __MODULE__
  @entropy_ms 10_000

  ##
  ## Public API
  ##
  @doc "Spawn a new process"
  @spec start_worker(module :: module(), args :: list(), name :: term()) :: :ok | {:error, :already_exists}
  def start_worker(module, args, name),
    do: GenServer.call(@name, {:start_worker, module, args, name})

  @doc "Stops a process"
  @spec stop(name :: term()) :: :ok | {:error, :not_found}
  def stop(name),
    do: GenServer.call(@name, {:stop_worker, name})

  @doc "Call to a worker"
  @spec call(name :: term(), request :: term()) :: any()
  def call(name, request) do
    :ok
  end

  @doc "Cast to a worker"
  @spec cast(name :: term(), request :: term()) :: :ok
  def cast(name, request) do
    :ok
  end


  ##
  ## GenServer callbacks
  ##
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: @name)

  def init(_opts) do
    debug("Flock starting on node #{node()}")

    # Receive node up/down messages.
    :net_kernel.monitor_nodes(true)

    # Initially the ring is built with the connected nodes and the local
    # node.
    :ok = Ring.new(nodes())

    # Start anti-entropy timer
    setup_anti_entropy_timer()

    {:ok, %__MODULE__{active: CRDT.new(), local: []}}
  end

  def handle_info(:anti_entropy, state) do
    debug("Flock performing anti_entropy on node #{node()}")

    Dispatch.broadcast({:update, state.active})

    setup_anti_entropy_timer()

    {:noreply, state}
  end
  def handle_info({up_down, n}, state)  when up_down in ~w(nodeup nodedown)a do
    case up_down do
      :nodeup ->
        Dispatch.forward(n, {:update, state.active})
        debug("connected to a new node #{n}")
        Ring.add_node(n)
      :nodedown ->
        debug("node #{n} went down or is unreachable")
        Ring.remove_node(n)
    end

    {:noreply, state}
  end
  def handle_info({:"$flock", n, {:update, msg}}, state) do
    debug("received #{inspect msg} from #{inspect n}")

    {:noreply, state}
  end

  def handle_call({:start_worker, module, args, name}, _from, state) do
    case CRDT.add(state.active, {module, args, name}) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}
      active ->
        debug("new process created #{inspect name}")
        local = rebalance(active, state.local)
        Dispatch.broadcast({:update, active})
        {:reply, :ok, %{state | active: active, local: local}}
    end
  end
  def handle_call({:stop_worker, name}, _from, state) do
    # TODO: remove by name, not the tuple
    case CRDT.remove_by(state.active, fn {_m, _a, n} -> n == name end) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}
      active ->
        debug("process stopped #{inspect name}")
        Dispatch.broadcast({:update, active})
        local = rebalance(active, state.local)
        {:reply, :ok, %{state | active: active, local: local}}
    end
  end

  ##
  ## Internal functions
  ##

  # Compute which workers must be running on the local node.
  defp mine(active) do
    Enum.filter(active, fn {_module, _arg, name} ->
      {:ok, node()} == Ring.get_node(name)
    end)
  end

  # Kill process not own by this node and start the ones that are own
  # by this node
  defp rebalance(active, local) do
    alive = CRDT.to_list(active)
    new_local = mine(alive)
    # Kill the workers on this node because they have migrated to some other
    # node.
    for {module, args, name} <- (local -- new_local) do
      [{pid, _}] = Registry.lookup(Flock.Registry, name)
      debug("killing process #{name}")
      # :ok = WorkerSupervisor.terminate_worker(pid)
    end

    # Start the new workers that after the node up/down are migrated to the
    # local node.
    for {module, args, name} <- (new_local -- local) do
      debug("starting process #{name}")
      {:ok, _pid} = WorkerSupervisor.start_worker({module, args, name})
    end

    new_local
  end

  # List of all connected nodes including local node.
  defp nodes(), do: [Node.self() | Node.list(:connected)]

  # Send an auto-message after @entropy_ms ms
  defp setup_anti_entropy_timer(),
    do: Process.send_after(self(), :anti_entropy, @entropy_ms)

  # Format a debug message
  defp debug(msg), do: Logger.debug("[#{@name}] #{msg}")
end


