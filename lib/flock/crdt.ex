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
    case element in set.added do
      true ->
        {:error, :already_exists}

      _ ->
        %__MODULE__{set | added: [element | set.added]}
    end
  end

  @doc "Remove an `element` from the CRDT"
  @spec remove(__MODULE__.t(), element :: any()) :: __MODULE__.t() | {:error, :not_found}
  def remove(%__MODULE__{} = set, element) do
    case element in set.added do
      false ->
        {:error, :not_found}

      _ ->
        %__MODULE__{set | added: set.added -- [element], removed: [element | set.removed]}
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
  def to_list(%__MODULE__{} = set), do: set.added -- set.removed
end
