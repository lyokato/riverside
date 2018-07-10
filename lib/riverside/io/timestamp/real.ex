defmodule Riverside.IO.Timestamp.Real do

  @behaviour Riverside.IO.Timestamp.Behaviour

  @impl Riverside.IO.Timestamp.Behaviour
  def seconds do
    DateTime.utc_now |> DateTime.to_unix(:seconds)
  end

  @impl Riverside.IO.Timestamp.Behaviour
  def milli_seconds do
    DateTime.utc_now |> DateTime.to_unix(:milliseconds)
  end

end
