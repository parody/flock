all:
	run

node:
	MIX_ENV=test iex --name $(name)@127.0.0.1 -S mix

run:
	MIX_ENV=test elixir --name test@127.0.0.1 -S mix run test/flock/create_processes.exs $(num)

node1:
	MIX_ENV=test iex --name node1@127.0.0.1 -S mix

node2:
	MIX_ENV=test iex --name node2@127.0.0.1 -S mix

node3:
	MIX_ENV=test iex --name node3@127.0.0.1 -S mix

call:
	MIX_ENV=test elixir --name call@127.0.0.1 -S mix run test/flock/call_processes.exs $(num)
