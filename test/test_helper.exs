ExUnit.start()

defmodule TestEchoHandler do

  require Logger
  use Riverside, otp_app: :riverside

  def authenticate(_cred, _params, _header, _peer) do
    {:ok, 1, %{}}
  end

  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end

end

defmodule TestAuthQueryHandler do

  require Logger
  use Riverside, otp_app: :riverside

  def authenticate(:default, params, _header, _peer) do
    if Map.has_key?(params, :user) do
      username = Map.fetch!(params, :user)
      if username == "valid_example" do
        {:ok, username, %{}}
      else
        {:error, :invalid_request}
      end
    else
      {:error, :invalid_request}
    end
  end

  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end

end

defmodule TestAuthBasicHandler do

  require Logger
  use Riverside, otp_app: :riverside

  def authenticate({:basic, username, password}, _params, _header, _peer) do
    if username == "valid_example" and password == "foobar" do
      {:ok, username, %{}}
    else
      {:error, :invalid_request}
    end
  end

  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end

end

defmodule TestAuthBearerTokenHandler do

  require Logger
  use Riverside, otp_app: :riverside

  def authenticate({:bearer, token}, _params, _header, _peer) do
    if token == "foobar" do
      {:ok, 1, %{}}
    else
      {:error, :invalid_token}
    end
  end

  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end

end
