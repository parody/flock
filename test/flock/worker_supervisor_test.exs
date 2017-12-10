defmodule Flock.WorkerSupervisorTest do
  use ExUnit.Case

  alias Flock.{WorkerSupervisor, WorkerMonitor}

  test "supervisor is supervising" do
    worker_name = "supervised bird"
    WorkerSupervisor.start_worker({MyBird, [self(), {:spawned, worker_name}], worker_name})
    assert_receive {:spawned, ^worker_name}

    assert :crashed = WorkerMonitor.call_worker(worker_name, :please_crash)
    assert_receive {:bird_terminated, :crash_requested}
    # Should receive the message back from the respawn
    assert_receive {:spawned, ^worker_name}

    assert :ok = WorkerSupervisor.terminate_worker(worker_name)
    assert {:error, :not_found} = WorkerSupervisor.terminate_worker("not started bird")
  end
end
