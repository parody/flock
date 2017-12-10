defmodule Flock do
  @moduledoc """
  Lightweight process registry and forgiving supervisor.
  """

  alias Flock.Manager

  @type worker_module :: module()
  @type worker_name :: term()
  @type worker_spec :: {module :: worker_module(), args :: list(), worker_name :: worker_name()}

  @doc """
  Adds a new worker to the flock.
  """
  @spec start(worker_spec :: Flock.worker_spec()) :: :ok | {:error, :already_exists}
  defdelegate start(worker_spec), to: Manager, as: :start_worker

  @doc """
  Makes a synchronous call to a worker in the flock.
  """
  @spec call(name :: Flock.worker_name(), request :: term()) :: any()
  defdelegate call(name, request), to: Manager

  @doc """
  Sends an asynchronous request to a worker in the flock.
  """
  @spec cast(name :: Flock.worker_name(), request :: term()) :: :ok
  defdelegate cast(name, request), to: Manager

  @doc """
  Stops a worker in the flock.
  """
  @spec stop(name :: Flock.worker_name()) :: :ok | {:error, :not_found}
  defdelegate stop(name), to: Manager
end
