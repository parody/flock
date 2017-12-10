all:
	run

deps:
	mix deps.get

node: deps
	MIX_ENV=test iex --name $(name)@127.0.0.1 -S mix

run: deps
	MIX_ENV=test elixir --name test@127.0.0.1 -S mix run test/flock/create_processes.exs $(num)

node1: deps
	MIX_ENV=test iex --name node1@127.0.0.1 -S mix

node2: deps
	MIX_ENV=test iex --name node2@127.0.0.1 -S mix

node3: deps
	MIX_ENV=test iex --name node3@127.0.0.1 -S mix

call: deps
	MIX_ENV=test elixir --name call@127.0.0.1 -S mix run test/flock/call_processes.exs $(num)
