defmodule Riverside.LocalDelivery do

  defmodule Topic do

    def user(user_id) do
      {:ws_user, user_id}
    end

    def session(user_id, session_id) do
      {:ws_session, user_id, session_id}
    end

  end

  @type frame_type :: :text | :binary

  @spec deliver_to_user(non_neg_integer, frame_type, any) :: :ok
    | {:error, :not_found}
  def deliver_to_user(user_id, frame_type, message) do
    Topic.user(user_id)
    |> deliver_message(frame_type, message)
  end

  @spec deliver_to_session(non_neg_integer, String.t, frame_type, any) :: :ok
    | {:error, :not_found}
  def deliver_to_session(user_id, session_id, frame_type, message) do
    Topic.session(user_id, session_id)
    |> deliver_message(frame_type, message)
  end

  def deliver_message(topic, frame_type, message) do
    dispatch(topic, {:deliver, frame_type, message})
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
