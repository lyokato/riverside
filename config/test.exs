use Mix.Config

config :riverside, Example.Handler,
  codec: Riverside.Codec.MessagePack

config :riverside,
  timestamp_module: Riverside.IO.Timestamp.Sandbox,
  random_module: Riverside.IO.Random.Sandbox

config :riverside, TestMaxConnectionHandler,
  max_connections: 1

config :riverside, TestAuthBasicHandler, []

config :riverside, TestAuthBearerTokenHandler, []

config :riverside, TestDirectRelayHandler, []

config :riverside, TestChannelBroadcastHandler, []

config :logger,
  level: :warn,
  truncate: 4096

