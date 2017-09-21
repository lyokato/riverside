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

## Usage

```elixir

defmodule YourApp.Session do

  require Logger

  use Riverside

  @impl true
  def authenticate({:basic, username, password}, queries, stash) do

    case YourApp.Authenticator.authenticate(username, password) do
      {:ok, user_id} -> {:ok, user_id, stash}
      _other         -> {:error, :invalid_request}
    end

  end
  def authenticate(_credentials, _queries, _stash) do

    {:error, :invalid_request}

  end

  @impl true
  def init(session) do
    {:ok, session}
  end

  @impl true
  def handle_message(message, session) do
    {:ok, session}
  end

  @impl true
  def terminate(session) do
    :ok
  end

end
```

config.exs

```elixir
```

your application starter.

```elixir


```

### Session Module

Define your own Session module with **Riverside**.

Implement following callback functions which **Riverside** requires.

- authenticate/3
- init/1
- handle_message/2
- terminate

#### authenticate/3

Arguments

* credential - :default, {:basic, username, password}, {:bearer, token}
* queries - Map contains qury-string params
* stash - Map kept while this session. at the timing of authentication this is empty. You can put your fovorite preference data.

#### Call Riverside.Spec.child_spec/1

```elixir
Riverside.Spec.child_spec([port: 3000, path: "/", module: YourApp.Session])
```


## Author

Lyo Kaot <lyo.kato __at__ gmail.com>

