require Logger

# Wait for libcluster to connect to the mesh
Process.sleep(5000)

num_processes =
  case System.argv() do
    [n] when is_bitstring(n) -> String.to_integer(n)
    _ -> 100
  end

Logger.debug("calling #{num_processes} birds")
for n <- 1..num_processes do
  name = "bird:#{n}"
  res = Flock.call(name, :where_are_you?)
  Logger.debug("bird #{name} replied #{inspect res}")
end
