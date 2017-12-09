defmodule Flock.WorkerSupervisor do
  @moduledoc """
  Flock workers supervisor
  """

  use Supervisor

  @name __MODULE__

  alias Flock.WorkerMonitor

  #
  # API
  #

  @doc """
  Starts the `Flock.WorkerSupervisor` linked to the current process
  """
  @spec start_link(arg :: any()) :: Supervisor.on_start()
  def start_link(arg),
      do: Supervisor.start_link(__MODULE__, arg, name: @name)

  @doc """
  Starts a child worker based on `worker_spec`
  """
  @spec start_worker(worker_spec :: WorkerMonitor.worker_spec()) :: Supervisor.on_start_child()
  def start_worker(worker_spec),
      do: Supervisor.start_child(@name, [worker_spec])

  @doc """
  Terminates the worker with name `worker_name`
  """
  @spec terminate_worker(worker_name :: WorkerMonitor.worker_name()) :: :ok | {:error, :not_found}
  def terminate_worker(worker_name) do
    case WorkerMonitor.whereis(worker_name) do
      :not_found ->
        {:error, :not_found}
      pid when is_pid(pid) ->
        Supervisor.terminate_child(@name, pid)
    end
  end

  def init(_arg) do
    Supervisor.init([
      WorkerMonitor
    ], strategy: :simple_one_for_one)
  end
end
