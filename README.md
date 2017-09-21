# Riverside

**TODO: Add description**

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

### Session Module

```elixir

defmodule YourApp.Session do

  use Riverside

  @impl true
  def authenticate({:basic, username, password}, queries, stash) do
    user_id = YourApp.Authenticator.authenticate(username, password)
    {:ok, user_id, stash}
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

### Setup Configuration

config.exs

```elixir
```

### Setup Supervisors

```elixir


```

#### Call Riverside.Spec.child_spec/1

```elixir
RiverSide.Spec.child_spec([port: 3000, path: "/", module: YourApp.Session])
```


