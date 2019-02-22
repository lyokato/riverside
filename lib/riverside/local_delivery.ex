defmodule Riverside.LocalDelivery do
  alias Riverside.Codec
  alias Riverside.Session

  defmodule Topic do
    def channel(channel_id) do
      "__channel__:#{channel_id}"
    end

    def user(user_id) do
      "__user__:#{user_id}"
    end

    def session(user_id, session_id) do
      "__session__:#{user_id}/#{session_id}"
    end
  end

  @type destination ::
          {:user, Session.user_id()}
          | {:session, Session.user_id(), String.t()}
          | {:channel, term}

  @spec deliver(destination, {Codec.frame_type(), any}) :: no_return
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
    Topic.channel(channel_id) |> sub()
  end

  def leave_channel(channel_id) do
    Topic.channel(channel_id) |> unsub()
  end

  def close(user_id, session_id) do
    Topic.session(user_id, session_id)
    |> dispatch(:stop)
  end

  defp dispatch(topic, message) do
    pub(topic, message)
  end

  def register(user_id, session_id) do
    Topic.user(user_id) |> sub()
    Topic.session(user_id, session_id) |> sub()
  end

  defp sub(topic) do
    Registry.register(Riverside.PubSub, topic, [])
  end

  defp unsub(topic) do
    Registry.unregister(Riverside.PubSub, topic)
  end

  defp pub(topic, message) do
    Registry.dispatch(Riverside.PubSub, topic, fn entries ->
      entries |> Enum.each(fn {pid, _item} -> send(pid, message) end)
    end)
  end
end
