defmodule Riverside.IO.Timestamp do

  @impl_mod Application.get_env(:riverside, :timestamp_module, Riverside.IO.Timestamp.Real)

  defmodule Behaviour do
    @callback seconds() :: non_neg_integer
    @callback milli_seconds() :: non_neg_integer
  end

  @behaviour Behaviour

  def seconds() do
    @impl_mod.seconds()
  end

  def milli_seconds() do
    @impl_mod.milli_seconds()
  end

end
