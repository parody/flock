defmodule Flock.Dispatch do
  @moduledoc """
  Inter-node communication API
  """

  @manager Flock.Manager

  #
  # API
  #

  @doc """
  Broadcast `message` to `nodes`

  By default the list of nodes does not include the local node
  """
  @spec broadcast(message :: term()) :: :ok
  def broadcast(message, nodes \\ Node.list()) do
    msg = {:"$flock", message}
    _ = for n <- nodes, is_atom(n), do: send({@manager, n}, msg)

    :ok
  end

  @doc "Forwards the `message` to the flock manager in `node`"
  @spec forward(node(), message :: term()) :: :ok
  def forward(node, message) when is_atom(node) do
    send({@manager, node}, {:"$flock", message})

    :ok
  end
end
