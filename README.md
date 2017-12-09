# Flock

Flock is a lightweight clusering library for Erlang/Elixir applications.

This project is part of the SpawnFest 2017, a 48hs comptetition so
it could contain unimplemented features or bugs.

# How it works?
## New birds are born

> A flock is a group of *birds* and birds live in *nests*

Flock lets you spawn processes (*birds*), and decides on which node (*nest*) to run
them based on a consistent hash mechanism (a hashring) balancing the
load over the cluster nodes.

## Bird migration

> When resources are scarce *birds* tend to migrate

When a node joins or leaves the cluster
the processes are rebalanced to the available nodes.
This is, the existing process are killed and restarted somewhere
else in the cluster. No `handoff` mechanism is implemented.

## Birds fly away, but they have names

> If you love them set them free...

The spawned processes are __NOT__ linked to their fathers.
You can communicate with them by a _required_ name. This name
is only valid inside Flock (it is not registered on the VM).

## Birdwatching is very popular

> Can your son distinguish his pet canary from another?

Flock processes are supervised locally on the node. If a process
ends abnormally, the supervisor will restart it.
The newly start processed will have the same name
but it will not have the same state than its predecesor.
This may be solved by recreating the process state from an external *source of truth*.

## All animals are mortal, birds are animals, ergo they are mortal

> Dig a hole in your back yard

When a process ends gracefully (with a normal exit status) it is removed from the
set of alive processes.

## I spot a bird!

> If you know the name of a bird you can call it

Flock provides `call` and `cast` much like the one in the gen_server. The request
is routed to the correct node and then to your process.

## Lets go hunting

> If the canary is gone, get out of the mine

You can tell Flock to deliverately kill a process.

# Architechture


## Isn' t this a hard problem to solve?

**Yes**, it is a very hard problem to solve, but we have relaxed some guarantees:
* Processes are not remotely (cross node) but locally monitored
* Starting a process only guarantees that the local node is aware of your request. The process
is **NOT** started after the call. Eventually the new process will be known to all nodes
and the node resposible for that process wil start it.
* Stopping processes has the same behaviour than starting them, the process is **NOT** stoped after the call
but it will eventually be stopped.
* You never talk directly to your process but go thorough Flock. This adds some overhead.

## Hash ring
## Cluster

It is based on distributed Erlang.

## CRDT

# Test and benchmarks

# When should I use it?

# Example

# About the team



