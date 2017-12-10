defmodule MyBird do
  @moduledoc "Flock test worker"

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def init([test_pid, spawn_message]) do
    send(test_pid, spawn_message)
    {:ok, test_pid}
  end

  def init(_init) do
    {:ok, nil}
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

  def handle_cast(:bye, s) do
    {:stop, :normal, s}
  end

  def handle_cast(:hi, s) do
    {:noreply, s}
  end

  def handle_cast(:byebye, s) do
    {:stop, :normal, s}
  end

  def terminate(msg, test_pid) when is_pid(test_pid)do
    send(test_pid, {:bird_terminated, msg})
    :normal
  end
  def terminate(:normal, _state) do
    :normal
  end
end
