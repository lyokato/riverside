use Mix.Config

config :riverside,
  session_module: Example.Session,
  port: 3000,
  connection_timeout: 120_000,
  reuse_port: true,
  authentication: {:basic, "example.org"}

config :logger,
  level: :debug,
  truncate: 4096

