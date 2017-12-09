defmodule Flock.CRDT do
  defstruct [:added, :removed]
  @type t :: %__MODULE__{added: list(), removed: list()}

  @spec new() :: __MODULE__.t()
  def new, do: %__MODULE__{added: [], removed: []}

  @spec add(__MODULE__.t(), element :: any()) :: __MODULE__.t() | {:error, reason :: String.t()}
  def add(%__MODULE__{} = s, e) do
    case e in s.added do
      true -> {:error, "Element already exists."}
      _ -> %__MODULE__{s | added: [e | s.added]}
    end
  end

  @spec remove(__MODULE__.t(), element :: any()) ::
          __MODULE__.t() | {:error, reason :: String.t()}
  def remove(%__MODULE__{} = s, e) do
    case e in s.added do
      false -> {:error, "Element does not exists."}
      _ -> %__MODULE__{s | added: s.added -- [e], removed: [e | s.removed]}
    end
  end

  @spec join(__MODULE__.t(), __MODULE__.t()) :: __MODULE__.t()
  def join(%__MODULE__{} = s1, %__MODULE__{} = s2) do
    %__MODULE__{
      added: Enum.uniq((s1.added ++ s2.added) -- (s1.removed ++ s2.removed)),
      removed: Enum.uniq(s1.removed ++ s2.removed)
    }
  end

  @spec to_list(__MODULE__.t()) :: list()
  def to_list(%__MODULE__{} = s), do: s.added -- s.removed
end
