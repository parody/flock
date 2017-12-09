defmodule Flock.WorkerMonitor do
  @moduledoc """
  This module is intended to take care of one bird in the flock
  """

  use GenServer, start: {__MODULE__, :start_worker, []}, restart: :transient

  @name __MODULE__

  #
  # API
  #

  @doc """
  Spawn a new worker based on `worker_spec`
  """
  @spec start_worker(worker_spec :: Flock.worker_spec()) :: GenServer.on_start()
  def start_worker({_module, _args, name} = worker_spec) do
    GenServer.start_link(@name, worker_spec, name: via_tuple(name))
  end

  @doc """
  Send `msg` to `name` and return the response

  The call will block `timeout` milliseconds before returning
  """
  @spec call_worker(name :: Flock.worker_name(), msg :: any(), timeout :: pos_integer() | :infinity) :: term()
  def call_worker(name, msg, timeout \\ 5_000) do
    GenServer.call(via_tuple(name), {msg, timeout}, timeout)
  end

  @doc """
  Cast `msg` to `name`

  This is the homologous to `GenServer.cast/2`
  """
  @spec cast_worker(name :: Flock.worker_name(), msg :: any()) :: :ok
  def cast_worker(name, msg) do
    GenServer.cast(via_tuple(name), msg)
  end

  @doc """
  Returns the `pid` of a worker or `:not_found` if no process is associated with the given `worker_name`
  """
  @spec whereis(worker_name :: Flock.worker_name()) :: pid() | :not_found
  def whereis(worker_name) do
    case Registry.lookup(Flock.Registry, worker_name) do
      [] -> :not_found
      [{pid, _}] -> pid
    end
  end

  #
  # GenServer callbacks
  #

  def init({module, args, worker_name}) do
    # Don't crash on bird crashes
    Process.flag(:trap_exit, true)

    with {:ok, worker_pid} <- module.start_link(args) do
      {:ok, {worker_pid, worker_name}}
    end
  end

  def handle_call({msg, timeout}, from, {worker_pid, _worker_name} = s) do
    _ =
      Task.start(fn ->
        response = GenServer.call(worker_pid, msg, timeout)
        GenServer.reply(from, response)
      end)

    {:noreply, s}
  end

  def handle_cast(msg, {worker_pid, _worker_name} = s) do
    :ok = GenServer.cast(worker_pid, msg)
    {:noreply, s}
  end

  def handle_info({:EXIT, worker_pid, :normal}, {worker_pid, worker_name} = s) do
    # call manager to remove this bird from the flock
    :ok = Flock.Manager.remove(worker_name)
    {:stop, :normal, s}
  end

  def handle_info({:EXIT, worker_pid, reason}, {worker_pid, _worker_name} = s) do
    ## Let supervisor respawn this bird
    {:stop, reason, s}
  end

  #
  # Internal functions
  #

  defp via_tuple(worker_name) do
    {:via, Registry, {Flock.Registry, worker_name}}
  end
end
