defmodule SingleNodeIntegrationTest do
  use ExUnit.Case

  test "starting, calling and stopping worker" do
    my_self = self()
    assert :ok = Flock.start({MyBird, [my_self, "Hi!"], :parrot})
    assert :your_first_speech == Flock.call(:parrot, {:please_reply, :your_first_speech})
    :ok = Flock.cast(:parrot, {:please_reply_me, my_self, :now_by_cast})
    assert_receive :now_by_cast
    assert :ok == Flock.stop(:parrot)
  end
end
