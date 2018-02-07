# Riverside

**[WIP] This project is not stable yet**

Simple WebSocket Server Framework for Elixir

## Installation

```elixir
def deps do
  [{:riverside, github: "lyokato/riverside", tag: "0.2.2"}]
end
```

## Usage Example

```elixir

config :my_app, MyApp.Handler,
  authentication: {:basic, "example.org"},
  codec: Riverside.Codec.JSON,
  connection_timeout: 120_000,
  max_connections: 10_000,
  transmission_limit: [duration: 2_000, capacity: 50]
```

```elixir
defmodule MyApp.Handler do

  require Logger

  use Riverside, otp_app: :my_app

  @impl true
  def authenticate({:basic, username, password}, params, headers, peer) do

    case MyApp.Authenticator.authenticate(username, password) do
      {:ok, user_id}             -> {:ok, user_id, %{}}
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

    deliver_user(user_id, outgoing_message)

    {:ok, session, state}
  end

  @impl true
  def terminate(session) do
    :ok
  end

end
```

And you have to append Riverside processes into your application's supervisor tree.

```elixir
defmodule MyApp

  use Application

  dof init do
  end

  def start(_type, _args) do

    opts = [strategy: one_for_one,
            name:     MyApp.Supervisor]

    children = [
        # other children...
      {Riverside, [MyApp.Handler, [port: 3000, path: "/"]]},
     ]

    Supervisor.start_link(children, opts)

  end

end

```

### Handler Module

Define your own Handler module with **Riverside**.

Implement following callback functions which **Riverside** requires.

- authenticate/4
- init/2
- handle_message/3
- handle_info/3
- terminate/2

### Spec Configuration

```elixir
{Riverside, [MyApp.Handler, [port: 3000, path: "/"]]},
```

First argument is the Handler module you prepared beforehand.

Second is keyword list

#### port

Port number of the WebSocket endpoint.

#### path

URL path for the WebSocket endpoint. "/" is set by default.

For instance, if you set "/foo", your clinet should access to the endpoint URL like following

```
ws://example.org/foo
```

#### reuse_port

Boolean flag for TCP's SO_REUSEPORT.

#### router

Plug routing module. Riverside.Router is set by default.

## Author

Lyo Kaot <lyo.kato __at__ gmail.com>

