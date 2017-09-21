defmodule Riverside.LocalDelivery do

  defmodule Topic do

    def channel(channel_id) do
      {:ws_channel, channel_id}
    end

    def user(user_id) do
      {:ws_user, user_id}
    end

    def session(user_id, session_id) do
      {:ws_session, user_id, session_id}
    end

  end

  @type frame_type :: :text | :binary

  @type destination :: {:user, non_neg_integer}
                     | {:session, non_neg_integer, String.t}
                     | {:channel, term}

  @spec deliver(destination, {frame_type, any}) :: no_return
  def deliver({:user, user_id}, {frame_type, message}) do
    Topic.user(user_id)
    |> deliver_message(frame_type, message)
  end
  def deliver({:session, user_id, session_id}, {frame_type, message}) do
    Topic.session(user_id, session_id)
    |> deliver_message(frame_type, message)
  end
  def deliver({:channel, channel_id}, {frame_type, message}) do
    Topic.channel(channel_id)
    |> deliver_message(frame_type, message)
  end

  def deliver_message(topic, frame_type, message) do
    dispatch(topic, {:deliver, frame_type, message})
  end

  def join_channel(channel_id) do
    :ebus.sub(self(), Topic.channel(channel_id))
  end

  def leave_channel(channel_id) do
    :ebus.unsub(self(), Topic.channel(channel_id))
  end

  def close(user_id, session_id) do
    Topic.session(user_id, session_id)
    |> dispatch(:stop)
  end

  defp dispatch(topic, message) do
    :ebus.pub(topic, message)
  end

  def register(user_id, session_id) do
    :ebus.sub(self(), Topic.user(user_id))
    :ebus.sub(self(), Topic.session(user_id, session_id))
  end

end
