defmodule LimitterTest do
  use ExUnit.Case

  alias Riverside.Session.TransmissionLimitter

  setup do
    Riverside.IO.Timestamp.Sandbox.start_link
    :ok
  end

  test "enough capacity for step-count" do

    setup_timestamps(1..100)

    duration = 100
    capacity =  10
    limitter1 = TransmissionLimitter.new()

    result = step(limitter1, duration, capacity, 9)
    refute result == :error

  end

  test "not enough capacity for step-count" do

    setup_timestamps(1..100)

    duration = 100
    capacity =  10
    limitter1 = TransmissionLimitter.new()

    result = step(limitter1, duration, capacity, 10)
    assert result == :error

  end

  test "over capacity after duration" do

    setup_timestamps(1..100)

    duration = 100
    capacity =  10
    limitter1 = TransmissionLimitter.new()

    result = step(limitter1, duration, capacity, 9)
    refute result == :error

    setup_timestamps(200..300)
    result = step(limitter1, duration, capacity, 9)
    refute result == :error

    setup_timestamps(300..400)
    result = step(limitter1, duration, capacity, 9)
    refute result == :error

  end

  test "over capacity on second duration" do

    setup_timestamps(1..100)

    duration = 100
    capacity =  10
    limitter1 = TransmissionLimitter.new()

    result = step(limitter1, duration, capacity, 9)
    refute result == :error

    setup_timestamps(200..300)
    result = step(limitter1, duration, capacity, 10)
    assert result == :error

  end

  defp setup_timestamps(range) do
    range
    |> Enum.map(&(&1 + 1500_000_000))
    |> Riverside.IO.Timestamp.Sandbox.set_milli_seconds()
  end

  defp step(limitter, _duration, _capacity, 0) do
    {:ok, limitter}
  end
  defp step(limitter, duration, capacity, rest) do
    case TransmissionLimitter.countup(limitter, duration, capacity) do
      {:ok, limitter2} ->
          step(limitter2, duration, capacity, rest - 1)

       _ -> :error
    end
  end

end

