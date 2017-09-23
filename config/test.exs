use Mix.Config

config :riverside, Example.Handler,
    authentication: {:basic, "exmaple.org"},
    codec: Riverside.Codec.MessagePack,
    connection_timeout: 60_000

config :logger,
  level: :debug,
  truncate: 4096

