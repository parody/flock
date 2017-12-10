defmodule Flock.Manager do
  @moduledoc """
  This is the core module of Flock

  It is in charged of keeping track of alive processes, communicating
  changes to other nodes, and receiving notifications of processes
  ending and updates from another node
  """

  use GenServer

  alias Flock.{CRDT, Dispatch, Ring, WorkerSupervisor, WorkerMonitor}

  require Logger

  defstruct [:active, :local]

  @type t :: %__MODULE__{active: term(), local: list()}

  @name __MODULE__
  @entropy_ms 100_000

  #
  # API
  #

  @doc "Spawn a new process"
  @spec start_worker(worker_spec :: Flock.worker_spec()) :: :ok | {:error, :already_exists}
  def start_worker(worker_spec), do: GenServer.call(@name, {:start_worker, worker_spec})

  @doc "Stops a process"
  @spec stop(name :: Flock.worker_name()) :: :ok | {:error, :not_found}
  def stop(name), do: GenServer.call(@name, {:stop_worker, name})

  @doc "Removes a process on normal exit"
  @spec remove(name :: Flock.worker_name()) :: :ok | {:error, :not_found}
  def remove(name), do: GenServer.call(@name, {:remove_worker, name})

  @doc "Call to a worker"
  @spec call(name :: Flock.worker_name(), request :: term()) :: any()
  def call(name, request) do
    {:ok, n} = Ring.get_node(name)

    case :rpc.call(n, WorkerMonitor, :call_worker, [name, request]) do
      {:badrpc, {:EXIT, {:noproc, _}}} ->
        {:error, :not_found}

      {:badrpc, error} ->
        {:error, error}

      response ->
        response
    end
  end

  @doc "Cast to a worker"
  @spec cast(name :: Flock.worker_name(), request :: term()) :: :ok
  def cast(name, request) do
    {:ok, n} = Ring.get_node(name)
    true = :rpc.cast(n, WorkerMonitor, :cast_worker, [name, request])
    :ok
  end

  @doc "Returns if the process named `name` is alive using local node information"
  @spec alive?(name :: Flock.worker_name()) :: boolean() | {:error, reason :: String.t}
  def alive?(name),
    do: GenServer.call(@name, {:alive?, name})

  @doc "Starts the Flock.Manager"
  def start_link(opts), do: GenServer.start_link(@name, opts, name: @name)

  #
  # GenServer callbacks
  #

  def init(_opts) do
    debug("starting on node #{node()}")

    # Receive node up/down messages.
    _ = :net_kernel.monitor_nodes(true)

    # Initially the ring is built with the connected nodes and the local
    # node.
    :ok = Ring.new(nodes())

    # Start anti-entropy timer
    setup_anti_entropy_timer()

    {:ok, %__MODULE__{active: CRDT.new(), local: []}}
  end

  def handle_call({:start_worker, {_module, _args, name} = worker_spec}, _from, state) do
    case CRDT.add(state.active, worker_spec) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      active ->
        debug("new process created #{inspect(name)}")
        local = rebalance(active, state.local)
        Dispatch.broadcast({:update, active})
        {:reply, :ok, %{state | active: active, local: local}}
    end
  end

  def handle_call({:stop_worker, name}, _from, state) do
    case CRDT.remove_by(state.active, fn {_m, _a, n} -> n == name end) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      active ->
        debug("process stopped #{inspect(name)}")
        Dispatch.broadcast({:update, active})
        local = rebalance(active, state.local)
        {:reply, :ok, %{state | active: active, local: local}}
    end
  end

  def handle_call({:remove_worker, name}, _from, state) do
    with {:ok, worker} <- CRDT.get_by(state.active, fn {_m, _a, n} -> n == name end),
         active <- CRDT.remove(state.active, worker)
    do
      debug("process removed #{inspect name}")
      Dispatch.broadcast({:update, active})
      {:reply, :ok, %{state | active: active, local: state.local -- [worker]}}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
  # TODO: Include a function get_name
  def handle_call({:alive?, name}, _from, state) do
    case CRDT.get_by(state.active, fn {_m, _a, n} -> n == name end) do
      {:ok, {_m, _a, ^name}} ->
        {:reply, true, state}
      {:error, :not_found} ->
        {:reply, false, state}
    end
  end

  def handle_info({up_down, n}, state) when up_down in ~w(nodeup nodedown)a do
    case up_down do
      :nodeup ->
        debug("connected to a new node #{n}")
        Ring.add_node(n)
        Process.send_after(self(), {:"$flock", :anti_entropy, n}, 500)
      :nodedown ->
        debug("node #{n} went down or is unreachable")
        Ring.remove_node(n)
    end

    local = rebalance(state.active, state.local)

    {:noreply, %{state | local: local}}
  end

  #
  # Internal flock messages
  #

  def handle_info({:"$flock", :anti_entropy, n}, state) do
    debug("sending updates to new node #{n}")

    Dispatch.forward(n, {:update, state.active})
    {:noreply, state}
  end
  def handle_info({:"$flock", :anti_entropy}, state) do
    debug("performing anti_entropy on node #{node()}")

    Dispatch.broadcast({:update, state.active})
    setup_anti_entropy_timer()

    {:noreply, state}
  end

  def handle_info({:"$flock", n, {:update, set}}, state) do
    debug("received updated set from #{n}")

    active = CRDT.join(set, state.active)
    local = rebalance(active, state.local)

    {:noreply, %{state | active: active, local: local}}
  end

  #
  # Internal functions
  #

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
    for {_module, _args, name} <- local -- new_local do
      debug("killing process #{name}")
      :ok = WorkerSupervisor.terminate_worker(name)
    end

    # Start the new workers that after the node up/down are migrated to the
    # local node.
    for {module, args, name} <- new_local -- local do
      debug("starting process #{name}")

      case WorkerSupervisor.start_worker({module, args, name}) do
        {:ok, _pid} ->
          :ok

        {:error, {:already_started, pid}} ->
          Logger.error("#{inspect(pid)} in #{inspect(node(pid))}")
      end
    end

    if length(alive) > 0 do
      num_active = length(alive)
      num_local = length(new_local)
      p = Float.round(num_local / num_active * 100, 2)
      debug("node #{node()} has #{p} % of the load (#{num_local} out of #{num_active})")
    end

    new_local
  end

  # List of all connected nodes including local node.
  defp nodes(), do: [Node.self() | Node.list(:connected)]

  # Send an auto-message after @entropy_ms ms
  # TODO: make this timeout random so different nodes do not resonate.
  defp setup_anti_entropy_timer(),
    do: Process.send_after(self(), {:"$flock", :anti_entropy}, @entropy_ms)

  # Format a debug message
  defp debug(msg), do: Logger.warn("[#{@name}] #{msg}")
end
