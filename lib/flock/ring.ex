defmodule Flock.Ring do
  @moduledoc """
  Hash ring interface for storing online nodes
  """

  @table __MODULE__

  #
  # API
  #

  @doc "Create a new hash ring singleton"
  @spec new(node_list :: [node()]) :: :ok | {:error, :already_started}
  def new(node_list \\ []) when is_list(node_list) do
    @table = :ets.new(@table, [:set, :named_table, :protected])

    HashRing.new()
    |> HashRing.add_nodes(node_list)
    |> update_ring()
  rescue
    _ ->
      {:error, :already_started}
  end

  @doc "Add a new `node` to the hash ring"
  @spec add_node(node()) :: :ok
  def add_node(node) do
    get_ring()
    |> HashRing.add_node(node)
    |> update_ring()
  end

  @doc "Remove `node` from the hash ring"
  @spec remove_node(node()) :: :ok
  def remove_node(node) do
    get_ring()
    |> HashRing.remove_node(node)
    |> update_ring()
  end

  @doc """
  Get a node for the given `term`

  It can return `{:error, :no_node}` if the hash ring is empty
  """
  @spec get_node(term()) :: {:ok, node()} | {:error, :no_node}
  def get_node(term) do
    ring = get_ring()

    case HashRing.key_to_node(ring, term) do
      node when is_atom(node) ->
        {:ok, node}

      {:error, _reason} ->
        {:error, :no_node}
    end
  end

  #
  # Internal functions
  #

  defp get_ring do
    [{:ring, ring}] = :ets.lookup(@table, :ring)
    ring
  end

  defp update_ring(ring) do
    true = :ets.insert(@table, {:ring, ring})
    :ok
  end
end
