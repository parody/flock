use Mix.Config

config :libcluster,
  topologies: [
    flock_topology: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        if_addr: {0,0,0,0},
        multicast_addr: {230,1,1,251},
        # a TTL of 1 remains on the local network,
        # use this to change the number of jumps the
        # multicast packets will make
        multicast_ttl: 1]]]

config :logger,
  level: :warn
