use Mix.Config

config :riverside, Example.Handler,
  authentication: {:basic, "exmaple.org"},
  codec: Riverside.Codec.MessagePack,
  connection_timeout: 60_000

config :riverside,
  timestamp_module: Riverside.IO.Timestamp.Real,
  random_module: Riverside.IO.Random.Real

config :riverside, TestHandler,
  connection_timeout: 60_000

config :logger,
  level: :debug,
  truncate: 4096

