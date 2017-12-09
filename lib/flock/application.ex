defmodule Flock.Application do
  @moduledoc false

  use Application

  alias Flock.WorkerSupervisor

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: FlockRegistry},
      WorkerSupervisor,
    ]

    opts = [strategy: :one_for_one, name: Flock.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
