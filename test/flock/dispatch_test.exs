defmodule Flock.DispatchTest do
  use ExUnit.Case

  alias Flock.Dispatch

  setup_all do
    pid = Process.whereis(Flock.Manager)
    true = Process.unregister(Flock.Manager)

    on_exit fn ->
      true = Process.register(pid, Flock.Manager)
    end

    :ok
  end

  test "basic dispatching" do
    ref = make_ref()

    Process.register(self(), Flock.Manager)

    assert :ok = Dispatch.broadcast({:test, ref}, [node()])
    assert_receive {:"$flock", _node, {:test, ^ref}}

    assert :ok = Dispatch.forward(node(), {:test, 1})
    assert_receive {:"$flock", _node, {:test, 1}}

    assert :ok = Dispatch.broadcast({:other, :test}, [:no@node])
    refute_receive {:"$flock", {:other, :test}}
  end
end
