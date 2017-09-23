# Riverside

Simple WebSocket Server Framework for Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `riverside` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:riverside, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/riverside](https://hexdocs.pm/riverside).

## Usage Example

```elixir

config :my_app, MyApp.Handler,
  authentication: {:basic, "example.org"},
  codec: Riverside.Codec.JSON,
  connection_timeout: 120_000

defmodule YourApp.Handler do

  require Logger

  use Riverside, otp_app: :my_app

  @impl true
  def authenticate({:basic, username, password}, params) do

    case YourApp.Authenticator.authenticate(username, password) do
      {:ok, user_id}             -> {:ok, user_id, %{}
      {:error, :invalid_request} -> {:error, :invalid_request}
      _other                     -> {:error, :server_error}
    end

  end

  @impl true
  def init(session, state) do
    {:ok, session, state}
  end

  @impl true
  def handle_message(incoming_message, session, state) do

    user_id = incoming_message["to"]
    content = incoming_message["content"]

    outgoing_message = %{from:    session.user_id,
                         content: content}

    deliver({:user, user_id}, outgoing_message)

    {:ok, session, state}
  end

  @impl true
  def terminate(session) do
    :ok
  end

end
```

your application starter.

```elixir

riverside_children = Riverside.Spec.child_spec(YourApp.Handler, port: 3000, path: "/"])

```

### Handler Module

Define your own Handler module with **Riverside**.

Implement following callback functions which **Riverside** requires.

- authenticate/2
- init/2
- handle_message/3
- handle_info/3
- terminate/2

## Author

Lyo Kaot <lyo.kato __at__ gmail.com>

