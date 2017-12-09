defmodule Flock do
  @moduledoc """
  Documentation for Flock.
  """

  @type worker_module :: module()
  @type worker_name :: term()
  @type worker_spec :: {module :: worker_module(), args :: list(), worker_name :: worker_name()}

  @doc """
  Hello world.

  ## Examples

      iex> Flock.hello
      :world

  """
  def hello do
    :world
  end
end
