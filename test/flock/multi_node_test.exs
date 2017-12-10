defmodule Flock.MultiNodeTest do
  use ExUnit.Case

  @tag :distributed
  test "multi-node test" do
    :ok = NodeManagerTest.create_test_node()

    Flock.start({MyBird, [], "uno"})
    Flock.start({MyBird, [], "dos"})

    :timer.sleep(1_000)

    node_a = Flock.call("uno", :whereis)
    node_b = Flock.call("dos", :whereis)

    assert "flock_b@" <> _hostname = to_string(node_a)
    assert "flock_a@" <> _hostname = to_string(node_b)
  end
end
