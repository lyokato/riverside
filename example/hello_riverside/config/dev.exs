import Config

config :hello_riverside, HelloRiverside.Handler,
  port: 3000,
  path: "/ws",
  max_connections: 10000,
  max_connection_age: :infinity,
  idle_timeout: 120_000,
  reuse_port: false,
  show_debug_logs: true,
  # tls: true,
  # tls_certfile: "/path/to/fullchain.pem",
  # tls_keyfile: "/path/to/privkey.pem",
  transmission_limit: [
    capacity: 50,
    duration: 2000
  ]

config :logger,
  level: :debug,
  truncate: 4096
