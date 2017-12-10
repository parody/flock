defmodule NodeManagerTest do

  @cmd [
    "run",
    "--no-halt",
    "-e",
    "Node.start(:flock_b, :shortnames)"
  ]

  def create_test_node do
    _ = Node.stop()

    {:ok, _} = Node.start(:flock_a, :shortnames)

    {:ok, _task} =
      Task.start_link(fn ->
        System.cmd("mix", @cmd, env: %{"MIX_ENV" => "test"})
      end)

    "flock_a@" <> hostname = to_string(node())
    other_node = "flock_b@" <> hostname |> String.to_atom()

    System.at_exit(fn _exit_code ->
      :rpc.call(other_node, :init, :stop, [])
    end)

    true = Node.connect(:"flock_b@#{hostname}")

    :ok
  end
end
