defmodule Flock.WorkerMonitor do
  @moduledoc """
  This module is intended to take care of one bird in the flock
  """

  use GenServer

  @name __MODULE__

  #
  # API
  #

  @doc """
  Spawn a new worker based on `module` using `args`

  The `name` is used for registering the process in the flock
  """
  @spec start_worker(module(), args :: list(), name :: term()) :: GenServer.on_start()
  def start_worker(module, args, name) do
    GenServer.start_link(@name, {module, args, name}, name: via_tuple(name))
  end

  @doc """
  Send `msg` to `name` and return the response

  The call will block `timeout` milliseconds before returning
  """
  @spec call_worker(name :: term(), msg :: any(), timeout :: pos_integer() | :infinity) :: term()
  def call_worker(name, msg, timeout \\ 5_000) do
    GenServer.call(via_tuple(name), {msg, timeout}, timeout)
  end

  @doc """
  Cast `msg` to `name`

  This is the homologous to `GenServer.cast/2`
  """
  @spec cast_worker(name :: term(), msg :: any()) :: :ok
  def cast_worker(name, msg) do
    GenServer.cast(via_tuple(name), msg)
  end

  @doc false
  def child_spec(module, args, name) do
    %{
      start: {__MODULE__, :start_worker, [module, args, name]},
      type: :worker,
      restart: :transient
    }
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

  def handle_info({:EXIT, worker_pid, :normal}, {worker_pid, _worker_name} = s) do
    ## TODO call manager to remove this bird from the flock
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
    {:via, Registry, {FlockRegistry, worker_name}}
  end
end
