use Mix.Config

config :riverside,
  connection_timeout: 120_000,
  reuse_port: true,
  authentication: {:basic, "example.org"}

config :logger,
  level: :debug,
  truncate: 4096

