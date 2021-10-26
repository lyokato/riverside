defmodule Riverside.Session do
  @abbreviation_header "Session"

  alias Riverside.Session.TransmissionLimitter

  @type user_id :: non_neg_integer | String.t()
  @type session_id :: String.t()

  @type t :: %__MODULE__{
          user_id: user_id,
          id: String.t(),
          abbreviation: String.t(),
          transmission_limitter: TransmissionLimitter.t(),
          peer: Riverside.PeerAddress.t(),
          trapping_pids: MapSet.t()
        }

  defstruct user_id: 0,
            id: "",
            abbreviation: "",
            transmission_limitter: nil,
            peer: nil,
            trapping_pids: nil

  @spec new(user_id, session_id, Riverside.PeerAddress.t()) :: t
  def new(user_id, session_id, peer) do
    abbreviation = create_abbreviation(user_id, session_id)

    %__MODULE__{
      user_id: user_id,
      id: session_id,
      abbreviation: abbreviation,
      transmission_limitter: TransmissionLimitter.new(),
      trapping_pids: MapSet.new(),
      peer: peer
    }
  end

  defp create_abbreviation(user_id, session_id) do
    "#{@abbreviation_header}:#{user_id}:#{String.slice(session_id, 0..5)}"
  end

  @spec should_delegate_exit?(t, pid) :: boolean
  def should_delegate_exit?(session, pid) do
    MapSet.member?(session.trapping_pids, pid)
  end

  @spec trap_exit(t, pid) :: t
  def trap_exit(%{trapping_pids: pids} = session, pid) do
    %{session | trapping_pids: MapSet.put(pids, pid)}
  end

  @spec forget_to_trap_exit(t, pid) :: t
  def forget_to_trap_exit(%{trapping_pids: pids} = session, pid) do
    %{session | trapping_pids: MapSet.delete(pids, pid)}
  end

  @spec countup_messages(t, keyword) ::
          {:ok, t}
          | {:error, :too_many_messages}
  def countup_messages(%{transmission_limitter: limitter} = session, opts) do
    duration = Keyword.fetch!(opts, :duration)
    capacity = Keyword.fetch!(opts, :capacity)

    case TransmissionLimitter.countup(limitter, duration, capacity) do
      {:ok, limitter} -> {:ok, %{session | transmission_limitter: limitter}}
      {:error, :too_many_messages} = error -> error
    end
  end

  def peer_address(%__MODULE__{peer: peer}) do
    "#{peer}"
  end
end

defimpl String.Chars, for: Riverside.Session do
  alias Riverside.Session

  def to_string(%Session{abbreviation: abbreviation}) do
    abbreviation
  end
end
