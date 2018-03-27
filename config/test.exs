use Mix.Config

config :riverside, Example.Handler,
  authentication: {:basic, "exmaple.org"},
  codec: Riverside.Codec.MessagePack

config :riverside,
  timestamp_module: Riverside.IO.Timestamp.Sandbox,
  random_module: Riverside.IO.Random.Sandbox

config :riverside, TestMaxConnectionHandler,
  max_connections: 1

config :riverside, TestAuthBasicHandler,
  authentication: {:basic, "exmaple.org"}

config :riverside, TestAuthBearerTokenHandler,
  authentication: {:bearer_token, "exmaple.org"}

config :riverside, TestDirectRelayHandler,
  authentication: {:bearer_token, "exmaple.org"}

config :riverside, TestChannelBroadcastHandler,
  authentication: {:bearer_token, "exmaple.org"}

config :logger,
  level: :debug,
  truncate: 4096

