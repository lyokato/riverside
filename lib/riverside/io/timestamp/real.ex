defmodule Riverside.IO.Timestamp.Real do

  @behaviour Riverside.IO.Timestamp.Behaviour

  def seconds do
    System.system_time(:seconds)
  end

  def milli_seconds do
    System.system_time(:milli_seconds)
  end

end
