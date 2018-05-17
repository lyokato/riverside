defmodule Riverside.MetricsInstrumenter do

  use Prometheus.Metric

  # TODO make registry configurable
  @registry :default

  def setup() do

    Gauge.declare([
      name: :riverside_connected_sessions_count,
      registry: @registry,
      help: "Connected Sessions Count"
    ])

    Counter.declare([
      name: :riverside_sessions_total,
      registry: @registry,
      help: "Total Sessions Count"
    ])

    Counter.declare([
      name: :riverside_incoming_messages_total,
      registry: @registry,
      labels: ["frame_type"],
      help: "Incoming Messages Count"
    ])

    Counter.declare([
      name: :riverside_outgoing_messages_total,
      registry: @registry,
      labels: ["frame_type"],
      help: "Outgoing Messages Count"
    ])

    Histogram.declare([
      name: :riverside_connected_duration_seconds,
      registry: @registry,
      buckets: [60, 180, 300, 600, 900, 1800, 3600, 7200, 10800, 21600, 43200, 86400],
      duration_unit: :seconds,
      help: "Connected Durations"
    ])

    :ok

  end

  def number_of_current_connections() do
    Gauge.value([
      name: :riverside_connected_sessions_count,
      registry: @registry
    ])
  end

  def countup_connections() do

    Counter.inc([
      name: :riverside_sessions_total,
      registry: @registry
    ])

    Gauge.inc([
      name: :riverside_connected_sessions_count,
      registry: @registry
    ])

    :ok

  end

  def countdown_connections(started_at) do

    Gauge.dec([
      name: :riverside_connected_sessions_count,
      registry: @registry
    ])

    diff = :erlang.monotonic_time - started_at

    Histogram.observe([
      name: :riverside_connected_duration_seconds,
      registry: @registry
    ], diff)

    :ok
  end

  def countup_incoming_messages(frame_type) do

    Counter.inc([
      name: :riverside_incoming_messages_total,
      labels: [frame_type],
      registry: @registry
    ])

    :ok
  end

  def countup_outgoing_messages(frame_type) do

    Counter.inc([
      name: :riverside_outgoing_messages_total,
      labels: [frame_type],
      registry: @registry
    ])

    :ok
  end

end
