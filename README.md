# Flock

Flock is a lightweight process registry and forgiving supervisor
library for Erlang/Elixir applications.

This project is part of the SpawnFest 2017 contest, a 48hs competition
so it could contain unimplemented features, surprises and/or bugs.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flock` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flock, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/flock](https://hexdocs.pm/flock).

# How it works?

## New birds are born

> A flock is a group of *birds* and birds live in *nests*

Flock lets you spawn processes (*birds*) and decides on which node
(*nest*) to run them based on a consistent hash mechanism (a hash
ring), spreading the load over the cluster nodes and respawning those
processes on the right node in case of node failures.

## Bird migration

> When resources are scarce *birds* tend to migrate

When a node joins or leaves the cluster the hash ring is rebalanced
and processes are migrated to the corresponding available nodes. As a
consistent hash is used, only some processes will be moved from the
node. This is, the existing process are killed and restarted somewhere
else in the cluster. No `handoff` mechanism is implemented.

## Birds fly away, but they have names

> If you love them set them free...

The spawned processes are __NOT__ linked to their fathers. You can
communicate with them by a _required_ name. This name is only valid
inside Flock (it is not registered on the BEAM).

## Birdwatching is very popular

> Can your son distinguish his pet canary from another?

Flock processes are supervised locally on the node. If a process ends
abnormally, the supervisor will restart it. The newly started
processed will have the same name but it will not have the same state
than it's predecessor. This issue may be solved by recreating the
process state from an external *source of truth*.

## All animals are mortal, birds are animals, ergo they are mortal

> Dig a hole in your back yard

When a process ends gracefully (with a `:normal` exit status) it is
removed from the set of alive processes.

## I spot a bird!

> If you know the name of a bird you can call it

Flock provides `call` and `cast` much like the one in the
`GenServer`. The request is routed to the correct node and then to
your process.

## Lets go hunting

> If the canary is gone, get out of the mine

You can tell Flock to deliberately kill a process with `stop`.

## One flock plus another flock makes one flock

> Two flocks form a bigger flock

A big issue in distributed systems is how to react to network
partitions. Flock favors availability over consistency, i.e. it stands
on the AP side. If the cluster is under a split-brain situation Flock
will run **one** instance of each process on each side of the
partition. Processes created on one side of the partition will not be
started on the other side. The same goes for stopping a process.

When the cluster is healed the processes from each side are
merged. Afterwards, only one instance of each process is run.

A partition or a re-grouping adds/removes nodes to the cluster, so at
this point the processes are rebalanced with the new cluster state.

# Architecture

## Isn't this a hard problem to solve?

**Yes**, it is a very hard problem to solve, but we have relaxed some
guarantees:

  * Processes are not remotely monitored (cross node) but locally.

  * Starting a process only guarantees that the local node is aware of
    your request. The process is **NOT** started after the
    call. Eventually the new process will be known to all nodes and
    the node responsible for that process will start it.

  * Stopping processes has the same behavior than starting them, the
    process is **NOT** stopped after the call but it will eventually
    be stopped.

  * You never talk directly to your process but thorough Flock. This
    may add some overhead.

  * Processes may resurrect or out-live a stop. As changes in the
    cluster are transmitted with eventual consistency, some
    information may be lost. For example if you start a process and
    your node goes down, it may have not communicated those changes to
    other nodes, so the process won't be started in any node. The same
    goes for stopping or after a graceful exit.

## Hash ring

Processes are assigned to nodes using a consistent hash ring. We are using
[libring](https://github.com/bitwalker/libring) library to this end.

## Node clustering

Flock is uses disterl for cross-node communication. Node discovery
is provided by the [libcluster](https://github.com/bitwalker/libcluster) library
also by [bitwalker](https://github.com/bitwalker) so double thanks to him.

## CRDT

A CRDT is used to keep track of alive processes. CRDT allow merge the information
of a partition in converging to a *safe* result. Flock uses an Add-Wins Observed/Removed
set. The curren implementation is a Home-baked less-than-ideal state-based AWORSet.

# Test it!

Testing Flock is easy. You need to have Elixir 1.5.2 installed on your system.
We provide an example `Makefile` to test it.

You will have to open as many terminal sessions as nodes you want to test.

In our case we will try it running:
* `make node1` on one terminal
* `make node2` on another terminal
* `make node3` on a third one
* `make run` on a fourth terminal. This last command will spawn 100 processes
(then number can be changed by running `make run num=10`) and balance them
on the cluster made up by those 4 nodes.

For calling those processes you can run `make call` which will call the local
and remote processes and tell where they are running.

And example output for `num=10` is:
```
19:21:33.165 [debug] bird bird:1 replied :"node1@127.0.0.1"
19:21:33.170 [debug] bird bird:2 replied :"node2@127.0.0.1"
19:21:33.175 [debug] bird bird:3 replied :"test@127.0.0.1"
19:21:33.175 [debug] bird bird:4 replied :"node1@127.0.0.1"
19:21:33.175 [debug] bird bird:5 replied :"node2@127.0.0.1"
19:21:33.179 [debug] bird bird:6 replied :"node3@127.0.0.1"
19:21:33.179 [debug] bird bird:7 replied :"node2@127.0.0.1"
19:21:33.179 [debug] bird bird:8 replied :"test@127.0.0.1"
19:21:33.179 [debug] bird bird:9 replied :"node1@127.0.0.1"
19:21:33.184 [debug] bird bird:10 replied :"call@127.0.0.1"
```
You can close any of the terminals and you *should* see the processes that were running
there being spawned on some other node.

The node reports basic statistics like ` node node3@127.0.0.1 has 20.0 % of the load (2 out of 10)`.

The example processes (`MyBird`) chirp every 10 seconds showing a message to
keep track of where they are running like:
```
19:26:01.561 [info]  bird bird:6 running on node node3@127.0.0.1
```

# Example

Flock is `GenServer`-friendly, you can start/call/cast/stop any GenServer without
any change. Supose you have a `GenServer`:
```elixir
defmodule MyBird do
  use GenServer

  require Logger

  def start_link(args),
    do: GenServer.start_link(__MODULE__, args, [])

  def init(name) do
    Process.send_after(self(), :chirp, 10_000)
    {:ok, name}
  end

  def handle_call(:ping, _from, s) do
    {:reply, :pong, s}
  end

  def handle_cast({:please_reply_me, pid, msg}, s) do
    send(pid, msg)
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
end
```

you can spawn on process by doing:
```
:ok = Flock.start({MyBird, ["Tweety"], "Tweety"})
```
This will start that process on *some* node after *some* time (eventually consistency rocks).

Then you can call that process by name like:
```
:pong = Flock.call("Tweety", :ping)
```

If the process ends abnormally it will be restarted by the local or remote supervisor.
If the process ends normally it will be removed from the set of alive processes.



# When should I use it?

# Documentation

Complete (not really) documentation of the code can be viewed on [https://spawnfest.github.io/flock/]

# About the team

Brought to you by:

  - [Germán Botto](https://github.com/germanbotto)
  - [Cristian Rosa](https://github.com/rosacris)
  - [Federico Bergero](https://github.com/fbergero)
  - [Ricardo Lanziano](https://github.com/arpunk)
