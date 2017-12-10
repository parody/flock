defmodule Flock.WorkerMonitorTest do
  use ExUnit.Case

  alias Flock.WorkerMonitor

  test "worker is alive and replying" do
    worker_name = "bird1"
    ref = make_ref()

    {:ok, _} = WorkerMonitor.start_worker({MyBird, [self(), {:spawned, worker_name}], worker_name})
    assert_receive {:spawned, ^worker_name}

    assert {:test, ^ref} = WorkerMonitor.call_worker(worker_name, {:please_reply, {:test, ref}})

    :ok = WorkerMonitor.cast_worker(worker_name, {:please_reply_me, self(), {:other, ref}})
    assert_receive {:other, ^ref}
  end
end
