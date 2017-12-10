defmodule Flock.RingTest do
  use ExUnit.Case

  alias Flock.Ring

  setup_all do
    :ok = Supervisor.terminate_child(Flock.Supervisor, Flock.Manager)

    on_exit fn ->
      {:ok, _} = Flock.Manager.start_link(:nothing)
    end
  end

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
