defmodule MyBird do
  @moduledoc "Flock test worker"

  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def init([test_pid, spawn_message]) do
    send(test_pid, spawn_message)
    {:ok, test_pid}
  end
  def init(name) do
    Process.send_after(self(), :chirp, 10_000)
    {:ok, name}
  end

  def handle_call(:where_are_you?, _from, s) do
    {:reply, node(), s}
  end
  def handle_call(:ping, _from, s) do
    {:reply, :pong, s}
  end
  def handle_call({:please_reply, msg}, _from, s) do
    {:reply, msg, s}
  end
  def handle_call(:please_crash, _from, s) do
    {:stop, :crash_requested, :crashed, s}
  end

  def handle_cast({:please_reply_me, pid, msg}, s) do
    send(pid, msg)
    {:noreply, s}
  end
  def handle_cast(:hi, s) do
    {:noreply, s}
  end
  def handle_cast(:byebye, s) do
    {:stop, :normal, s}
  end

  def handle_info(:chirp, name) do
    Logger.info("bird #{name} running on node #{node()}")
    Process.send_after(self(), :chirp, 10_000)
    {:noreply, name}
  end

  def terminate(msg, test_pid) when is_pid(test_pid)do
    send(test_pid, {:bird_terminated, msg})
    :normal
  end
  def terminate(:normal, _name) do
    :normal
  end
end
