# Flock

Flock is a lightweight process registry and forgiving supervisor
library for Erlang/Elixir applications.

This project is part of the SpawnFest 2017 contest, a 48hs competition
so it could contain unimplemented features, surprises and/or bugs.

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

## Node clustering

It currently uses disterl for cross-node communication.

## CRDT

Home-baked less-than-ideal state-based CRDT

# Test and benchmarks

# When should I use it?

# Example

# About the team

Brought to you by:

  - [Germán Botto](https://github.com/germanbotto)
  - [Cristian Rosa](https://github.com/rosacris)
  - [Federico Bergero](https://github.com/fbergero)
  - [Ricardo Lanziano](https://github.com/arpunk)
