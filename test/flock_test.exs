defmodule FlockTest do
  use ExUnit.Case
  doctest Flock

  test "greets the world" do
    assert Flock.hello() == :world
  end
end
