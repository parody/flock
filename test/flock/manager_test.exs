defmodule Flock.ManagerTest do
  use ExUnit.Case

  alias Flock.Manager

  test "starting a worker" do
    assert :ok = Manager.start_worker(MyBird, [], :tweety)
  end

  test "re-starting a worker" do
    assert :ok = Manager.start_worker(:module, [], :polly)
    assert {:error, _reason} = Manager.start_worker(:module, [], :polly)
  end

  test "calling a worker" do
    assert :ok = Manager.start_worker(:module, [], :birdy)
    assert :pong = Manager.call(:birdy, :ping)
  end

  test "casting a worker" do
    assert :ok = Manager.start_worker(:module, [], :ducky)
    assert :ok = Manager.cast(:ducky, :hi)
  end

  test "calling an unknown worker" do
    assert {:error, :not_found} = Manager.call(:dummy, :request)
  end

  test "stoping a worker" do
    assert :ok = Manager.start_worker(:module, [], :duffy_duck)
    assert :ok = Manager.stop(:duffy_duck)
  end

  test "stoping an unknow worker" do
    assert {:error, :not_found} = Manager.stop(:dummy)
  end

end
