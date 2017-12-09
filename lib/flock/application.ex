defmodule Flock.Application do
  @moduledoc false

  use Application

  alias Flock.{Manager, WorkerSupervisor}

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Flock.Registry},
      WorkerSupervisor,
      {Manager, []}
    ]

    opts = [strategy: :one_for_one, name: Flock.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
