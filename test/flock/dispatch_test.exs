defmodule Flock.DispatchTest do
  use ExUnit.Case

  alias Flock.Dispatch

  test "basic dispatching" do
    ref = make_ref()

    Process.register(self(), Flock.Manager)

    assert :ok = Dispatch.broadcast({:test, ref}, [node()])
    assert_receive {:"$flock", {:test, ^ref}}

    assert :ok = Dispatch.forward(node(), {:test, 1})
    assert_receive {:"$flock", {:test, 1}}

    assert :ok = Dispatch.broadcast({:other, :test}, [:no@node])
    refute_receive {:"$flock", {:other, :test}}
  end
end
