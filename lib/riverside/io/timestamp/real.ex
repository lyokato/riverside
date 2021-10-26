defmodule Riverside.IO.Timestamp.Real do
  @behaviour Riverside.IO.Timestamp.Behaviour

  @impl Riverside.IO.Timestamp.Behaviour
  def seconds do
    DateTime.utc_now() |> DateTime.to_unix(:second)
  end

  @impl Riverside.IO.Timestamp.Behaviour
  def milli_seconds do
    DateTime.utc_now() |> DateTime.to_unix(:millisecond)
  end
end
