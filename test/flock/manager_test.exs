defmodule Flock.ManagerTest do
  use ExUnit.Case

  alias Flock.Manager

  test "starting a worker" do
    assert :ok = Manager.start_worker(MyBird, [], :tweety)
  end

  test "re-starting a worker" do
    assert :ok = Manager.start_worker(MyBird, [], :polly)
    assert {:error, _reason} = Manager.start_worker(MyBird, [], :polly)
  end

  test "calling a worker" do
    assert :ok = Manager.start_worker(MyBird, [], :birdy)
    assert :pong = Manager.call(MyBird, :ping)
  end

  test "casting a worker" do
    assert :ok = Manager.start_worker(MyBird, [], :tux)
    assert :ok = Manager.cast(:tux, :hi)
  end

  test "calling an unknown worker" do
    assert {:error, :not_found} = Manager.call(:dummy, :request)
  end

  test "stoping a worker" do
    assert :ok = Manager.start_worker(MyBird, [], :duffy_duck)
    assert :ok = Manager.stop(:duffy_duck)
  end

  test "stoping an unknow worker" do
    assert {:error, :not_found} = Manager.stop(:dummy)
  end

end
