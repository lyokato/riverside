defmodule Riverside.Session.State do

  @abbreviation_header "Session"
  @session_id_length 20

  alias Riverside.IO.Random
  alias Riverside.Session.MessageCounter

  @type t :: %__MODULE__{user_id:         non_neg_integer,
                         id:              String.t,
                         abbreviation:    String.t,
                         message_counter: MessageCounter.t,
                         peer:            PeerInfo.t,
                         stash:           map}

  defstruct user_id:         0,
            id:              "",
            abbreviation:    "",
            message_counter: nil,
            peer:            nil,
            stash:           %{}

  def new(user_id, peer, stash) do

    session_id = create_session_id()
    abbreviation = create_abbreviation(user_id, session_id)

    %__MODULE__{user_id:         user_id,
                id:              session_id,
                abbreviation:    abbreviation,
                message_counter: MessageCounter.new(),
                peer:            peer,
                stash:           stash}
  end

  defp create_session_id() do
    Random.hex(@session_id_length)
  end

  defp create_abbreviation(user_id, session_id) do
    "<#{@abbreviation_header}:#{user_id}:#{String.slice(session_id, 0..5)}>"
  end

  def countup_messages(%{message_counter: counter}=state) do
    case MessageCounter.countup(counter) do

      {:ok, counter} ->
        {:ok, %{state|counter: counter}}

      {:error, :too_many_messages} ->
        {:error, :too_many_messages}
    end
  end

  def peer_address(%__MODULE__{peer: peer}) do
    "#{peer}"
  end

end

defimpl String.Chars, for: Riverside.Session.State do

  alias Riverside.Session.State

  def to_string(%State{abbreviation: abbreviation}) do
    abbreviation
  end

end
