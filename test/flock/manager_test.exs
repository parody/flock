defmodule Flock.ManagerTest do
  use ExUnit.Case

  alias Flock.Manager

  test "starting a worker" do
    assert :ok = Manager.start_worker({MyBird, [], :tweety})
  end

  test "re-starting a worker" do
    assert :ok == Manager.start_worker({MyBird, [], :polly})
    assert true == Manager.alive?(:polly)
    assert {:error, _reason} = Manager.start_worker({MyBird, [], :polly})
  end

  test "calling a worker" do
    assert :ok == Manager.start_worker({MyBird, [], :birdy})
    assert :pong == Manager.call(:birdy, :ping)
  end

  test "casting a worker" do
    assert :ok == Manager.start_worker({MyBird, [], :tux})
    assert :ok == Manager.cast(:tux, :hi)
  end

  test "calling an unknown worker" do
    assert {:error, :not_found} == Manager.call(:dummy, :request)
  end

  test "stoping a worker" do
    assert :ok == Manager.start_worker({MyBird, [], :duffy_duck})
    assert true == Manager.alive?(:duffy_duck)
    assert :ok == Manager.stop(:duffy_duck)
    assert false == Manager.alive?(:duffy_duck)
  end

  test "stoping an unknow worker" do
    assert {:error, :not_found} = Manager.stop(:dummy)
  end

  test "the worker ends normally" do
    assert :ok == Manager.start_worker({MyBird, [], :wingull})
    assert true == Manager.alive?(:wingull)
    assert :ok == Manager.cast(:wingull, :byebye)

    # Give some time for bird to kill itself
    Process.sleep(1000)

    assert false == Manager.alive?(:wingull)
  end
end
