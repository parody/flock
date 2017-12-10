defmodule Flock.CRDT do
  @moduledoc """
  Home-baked CRDT for worker tracking
  """

  defstruct [:added, :removed]

  @type t :: %__MODULE__{added: list(), removed: list()}

  #
  # API
  #

  @doc "Create a new CRDT"
  @spec new() :: __MODULE__.t()
  def new, do: %__MODULE__{added: [], removed: []}

  @doc "Add a new `element` to the CRDT"
  @spec add(__MODULE__.t(), element :: any()) :: __MODULE__.t() | {:error, :already_exists}
  def add(%__MODULE__{} = set, element) do
    case in_set?(set.added, element) do
      true ->
        {:error, :already_exists}

      _ ->
        %__MODULE__{set | added: [{UUID.uuid4(), element} | set.added]}
    end
  end

  @doc "Remove an `element` from the CRDT"
  @spec remove(__MODULE__.t(), element :: any()) :: __MODULE__.t() | {:error, :not_found}
  def remove(%__MODULE__{} = set, element) do
    case in_set?(set.added, element) do
      false ->
        {:error, :not_found}

      _ ->
        elem_ids = get_all(set.added, element)
        %__MODULE__{set | added: set.added -- elem_ids, removed: elem_ids ++ set.removed}
    end
  end

  @doc "Remove an `element` from the CRDT using a `predicate` as filter"
  @spec remove_by(__MODULE__.t(), predicate :: fun()) :: __MODULE__.t() | {:error, :not_found}
  def remove_by(%__MODULE__{} = set, predicate) do
    case filter(set.added, predicate) do
      [] ->
        {:error, :not_found}
      removed ->
        elem_ids = get_all(set.added, removed)
        %__MODULE__{set | added: set.added -- elem_ids, removed: elem_ids ++ set.removed}
    end
  end

  @doc "Remove an `element` from the CRDT using a fun as filter"
  @spec remove_by(__MODULE__.t(), predicate :: fun()) :: __MODULE__.t() | {:error, :not_found}
  def remove_by(%__MODULE__{} = set, predicate) do
    case Enum.filter(set.added, predicate) do
      [] ->
        {:error, :not_found}
      removed ->
        %__MODULE__{set | added: (set.added -- removed), removed: (set.removed ++ removed)}
    end
  end

  @doc "Get an `element` from the CRDT using a fun as filter"
  @spec get_by(__MODULE__.t(), predicate :: fun()) :: {:ok, any()} | {:error, :not_found}
  def get_by(%__MODULE__{} = set, predicate) do
    case Enum.filter(set.added, predicate) do
      [] -> {:error, :not_found}
      element -> {:ok, element}
    end
  end

  @doc "Join two sets"
  @spec join(__MODULE__.t(), __MODULE__.t()) :: __MODULE__.t()
  def join(%__MODULE__{} = s1, %__MODULE__{} = s2) do
    %__MODULE__{
      added: Enum.uniq((s1.added ++ s2.added) -- (s1.removed ++ s2.removed)),
      removed: Enum.uniq(s1.removed ++ s2.removed)
    }
  end

  @doc "Return the set elements as a list"
  @spec to_list(__MODULE__.t()) :: list()
  def to_list(%__MODULE__{} = set), do:
    set.added
    |> Enum.map(&elem(&1, 1))
    |> Enum.uniq()
  #
  # Internal functions
  #

  defp in_set?(set, element) do
    List.keymember?(set, element, 1)
  end

  defp get_all(set, element) do
    Enum.filter(set, fn {id, e} -> e == element end)
  end

  defp filter(set, predicate) do
    Enum.filter(set, fn {id, e} -> predicate.(e) end)
  end
end
