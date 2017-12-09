defmodule Flock.RingTest do
  use ExUnit.Case

  alias Flock.Ring

  test "singleton table" do
    assert :ok = Ring.new()
    assert {:error, :already_started} = Ring.new()

    assert :ok = Ring.add_node(:a@localhost)
    assert {:ok, :a@localhost} = Ring.get_node(:abc)

    assert :ok = Ring.remove_node(:a@localhost)
    assert {:error, :no_node} = Ring.get_node(:abc)

    assert :ok = Ring.remove_node(:a@localhost)
  end
end
