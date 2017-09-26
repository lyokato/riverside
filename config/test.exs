use Mix.Config

config :riverside, Example.Handler,
  authentication: {:basic, "exmaple.org"},
  codec: Riverside.Codec.MessagePack,
  connection_timeout: 60_000

config :riverside,
  timestamp_module: Riverside.IO.Timestamp.Sandbox,
  random_module: Riverside.IO.Random.Sandbox

config :riverside, TestHandler,
  connection_timeout: 60_000

config :riverside, TestEchoHandler,
  connection_timeout: 60_000

config :riverside, TestAuthQueryHandler,
  connection_timeout: 60_000

config :riverside, TestAuthBasicHandler,
  authentication: {:basic, "exmaple.org"},
  connection_timeout: 60_000

config :riverside, TestAuthBearerTokenHandler,
  authentication: {:bearer_token, "exmaple.org"},
  connection_timeout: 60_000

config :logger,
  level: :debug,
  truncate: 4096

