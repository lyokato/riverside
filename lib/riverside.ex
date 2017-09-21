defmodule Riverside do

  alias Riverside.State

  defmodule Behaviour do

    @type credential_type :: :default
                           | {:bearer_token, String.t}
                           | {:basic, String.t, String.t}

    @callback authenticate(credential_type, map, map) :: {:ok, non_neg_integer, map}
      | {:error, :invalid_token | :invalid_request}

    @callback init(State.t) :: {:ok, State.t} | {:error, any}

    @callback handle_message(any, State.t) :: {:ok, State.t}

    @callback terminate(State.t) :: :ok

  end

  defmacro __using__(_) do
    quote location: :keep do

      @behaviour Riverside.Behaviour

      import Riverside.LocalDelivery, only: [
        deliver_to_user: 3,
        deliver_to_session: 4,
        close: 2
      ]

      @impl true
      def authenticate(_cred, _queries, _stash) do
        {:error, :invalid_request}
      end

      @impl true
      def init(state) do
        {:ok, state}
      end

      @impl true
      def handle_message(_msg, state) do
        {:ok, state}
      end

      @impl true
      def terminate(_state) do
        :ok
      end

      defoverridable [
        authenticate: 3,
        init: 1,
        handle_message: 2,
        terminate: 1
      ]

    end
  end

end
