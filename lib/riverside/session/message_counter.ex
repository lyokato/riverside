defmodule Riverside.Session.MessageCounter do

  @type t :: %__MODULE__{count:      non_neg_integer,
                         started_at: non_neg_integer}

  defstruct count:      0,
            started_at: 0

  def new() do
    %__MODULE__{count:      0,
                started_at: Riverside.IO.Timestamp.milli_seconds()}
  end

  @spec countup(t, non_neg_integer, non_neg_integer) :: {:ok, t}
    | {:error, :too_many_messages}

  def countup(counter, duration, capacity) do

    now = Riverside.IO.Timestamp.milli_seconds()

    if counter.started_at + duration < now do

      {:ok,  %{counter| count: 1, started_at: now}}

    else

      count = counter.count + 1

      if count < capacity do

        {:ok, %{counter| count: count}}

      else

        {:error, :too_many_messages}

      end

    end
  end

end
