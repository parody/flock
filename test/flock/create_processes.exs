require Logger

num_processes =
  case System.argv() do
    [n] when is_bitstring(n) -> String.to_integer(n)
    _ -> 100
  end

Logger.debug("creating #{num_processes} birds")
for n <- 1..num_processes do
  name = "bird:#{n}"
 :ok = Flock.start({MyBird, [name], name})
end

Process.sleep(:infinity)
