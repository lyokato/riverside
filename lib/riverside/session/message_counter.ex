defmodule Riverside.Session.MessageCounter do

  @duration Application.get_env(:riverside, :session_message_counting_duration, 2_000)
  @capacity Application.get_env(:riverside, :capacity_of_session_message_in_duration, 50)

  @type t :: %__MODULE__{count:      non_neg_integer,
                         started_at: non_neg_integer}

  defstruct count:      0,
            started_at: 0

  def new() do
    %__MODULE__{count:      0,
                started_at: Riverside.IO.Timestamp.milli_seconds()}
  end

  @spec countup(t) :: {:ok, t} | {:error, :too_many_messages}

  def countup(counter) do

    now = Riverside.IO.Timestamp.milli_seconds()

    if counter.started_at + @duration < now do

      {:ok,  %{counter| count: 1, started_at: now}}

    else

      count = counter.count + 1

      if count < @capacity do

        {:ok, %{counter| count: count}}

      else

        {:error, :too_many_messages}

      end

    end
  end

end
