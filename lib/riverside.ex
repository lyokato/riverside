defmodule Riverside do
  @moduledoc ~S"""

  # Riverside - Plain WebSocket Server Framework for Elixir

  ## Getting Started

  ### Handler

  At first, you need to prepare your own `Handler` module with `use Riverside` line.

  in `handle_message/3`, process messages sent by client.
  This doesn't depend on some protocol like Socket.io.
  So do client-side, you don't need to prepared some libraries.

  ```elixir
  defmodule MySocketHandler do

    # set 'otp_app' param like Ecto.Repo
    use Riverside, otp_app: :my_app

    @impl Riverside
    def handle_message(msg, session, state) do

      # `msg` is a 'TEXT' or 'BINARY' frame sent by client,
      # process it as you like
      deliver_me(msg)

      {:ok, session, state}

    end

  end
  ```

  ### Application child_spec

  And in your `Application` module, set child spec for your supervisor.

  ```elixir
  defmodule MyApp do

    use Application

    def start(_type, _args) do
      [
        # ...
         {Riverside, [handler: MySocketHandler]}
      ]
      |> Supervisor.start_link([
        strategy: :one_for_one,
        name:     MyApp.Spervisor
      ])
    end

  end
  ```

  ### Configuration

  ```elixir
  config :my_app, MySocketHandler,
    port: 3000,
    path: "/my_ws",
    max_connections: 10000, # don't accept connections if server already has this number of connections
    max_connection_age: :infinity, # force to disconnect a connection if the duration passed. if :infinity is set, do nothing.
    idle_timeout: 120_000, # disconnect if no event comes on a connection during this duration
    reuse_port: false, # TCP SO_REUSEPORT flag
    show_debug_logs: false,
    transmission_limit: [
      capacity: 50,  # if 50 frames are sent on a connection
      duration: 2000 # in 2 seconds, disconnect it.
    ]
  ```

  I’ll show you detailed description below.
  But you will know most of them when you see them.

  ### Run

  Launch your application, then the WebSocket service is provided with an endpoint like the following.

  ```
  ws://localhost:3000/my_ws
  ```

  And at the same time, we can also access to

  ```
  http://localhost:3000/health
  ```

  If you send a HTTP GET request to this URL, it returns response with status code 200, and text content "OK".
  This is just for health check.

  And

  ```
  http://localhost:3000/metrics
  ```

  This endpoint shows prometheus-formatted metrics.

  These features are defined in a Plug Router named `Riverside.Router`, and this is configured as default `router` param for child spec. So, you can defined your own Plug Router if you set as below.

  **In your Application module**

  ```elixir
  defmodule MyApp do

    use Application

    def start(_type, _args) do
      [
        # ...
         {Riverside, [
           handler: MySocketHandler,
           router: MyRouter, # Set your Plug Router here
          ]}
      ]
      |> Supervisor.start_link([
        strategy: :one_for_one,
        name:     MyApp.Spervisor
      ])
    end

  end
  ```

  ## Handler's Callbacks

  You can also define callback functions other than `handle_message/3`.

  For instance, there are functions named `init`, `terminate`, and `handle_info`.
  If you are accustomed to GenServer, you can easily imagine what they are,
  though their interface is little bit different.

  ```elixir
  defmodule MySocketHandler do

    use Riverside, otp_app: :my_app

    @impl Riverside
    def init(session, state) do
      # initialization
      {:ok, session, state}
    end

    @impl Riverside
    def handle_message(msg, session, state) do
      deliver_me(msg)
      {:ok, session, state}

    end

    @impl Riverside
    def handle_info(into, session, state) do
      # handle message sent to this process
      {:ok, session, state}
    end

    @impl Riverside
    def terminate(reason, session, state) do
  　　# cleanup
      :ok
    end

  end
  ```
  ## Authentication and Session

  Here, I'll describe `authenticate/1` callback function.

  ```elixir
  defmodule MySocketHandler do

    use Riverside, otp_app: :my_app

    @impl Riverside
    def authenticate(req) do
      {username, password} = req.basic
      case MyAuthenticator.authenticate(username, password) do

        {:ok, user_id} ->
          state = %{}
          {:ok, user_id, state}

        {:error, :invalid_password} ->
          error = auth_error_with_code(401)
          {:error, error}
      end
    end

    @impl Riverside
    def init(session, state) do
      {:ok, session, state}
    end

    @impl Riverside
    def handle_message(msg, session, state) do
      deliver_me(msg)
      {:ok, session, state}

    end

    @impl Riverside
    def handle_info(into, session, state) do
      {:ok, session, state}
    end

    @impl Riverside
    def terminate(reason, session, state) do
      :ok
    end

  end
  ```

  The argument of `authenticate/1` is a struct of `Riverside.AuthRequest.t`.
  And it has **Map** members

  - queries: Map includes HTTP request's query params
  - headers: Map includes HTTP headers

  ```elixir

  # When client access with a URL such like ws://localhost:3000/my_ws?token=FOOBAR,
  # And you want to authenticate the `token` parameter ("FOOBAR", this time)

  @impl Riverside
  def authenticate(req) do
    # You can pick the parameter like as below
    token = req.queries["token"]
    # ...
  end
  ```

  ```elixir
  # Or else you want to authenticate with `Authorization` HTTP header.

  @impl Riverside
  def authenticate(req) do
    # You can pick the header value like as below
    auth_header = req.headers["authorization"]
    # ...
  end

  ```

  The fact is that, you don't need to parse **Authorization** header by yourself, if you want to do **Basic**
   or **Bearer** authentication.

  ```elixir

  # Pick up `username` and `password` from `Basic` Authorization header.
  # If it doesn't exist, `username` and `password` become empty strings.

  @impl Riverside
  def authenticate(req) do
    {username, password} = req.basic
    # ...
  end

  ```

  ```elixir
  # Pick up token value from `Bearer` Authorization header
  # If it doesn't exist, `token` become empty string.

  @impl Riverside
  def authenticate(req) do
    token = req.bearer_token
    # ...
  end
  ```

  ### Authentication failure

  If authentication failure, you need to return `{:error, Riverside.AuthError.t}`.
  You can build Riverside.AuthError struct with `auth_error_with_code/1`.
  Pass proper HTTP status code.

  ```elixir
  @impl Riverside
  def authenticate(req) do

    token = req.bearer_token

    case MyAuth.authenticate(token) do

      {:error, :invalid_token} ->
         error = auth_error_with_code(401)
         {:error, error}

      # _ -> ...

    end

  end
  ```

  You can use `put_auth_error_header/2` to put response header

  ```elixir
  error = auth_erro_with_code(400)
        |> puth_auth_error_header("WWW-Authenticate", "Basic realm=\"example.org\"")
  ```

  And two more shortcuts, `put_auth_error_basic_header` and `put_auth_error_bearer_header`.

  ```elixir
  error = auth_erro_with_code(401)
        |> puth_auth_error_basic_header("example.org")

  # This puts `WWW-Authenticate: Basic realm="example.org"`
  ```

  ```elixir
  error = auth_erro_with_code(401)
        |>  puth_auth_error_bearer_header("example.org")

  # This puts `WWW-Authenticate: Bearer realm="example.org"`
  ```

  ```elixir
  error = auth_erro_with_code(400)
        |>  puth_auth_error_bearer_header("example.org", "invalid_token")

  # This puts `WWW-Authenticate: Bearer realm="example.org", error="invalid_token"`
  ```
  ### Successful authentication

  ```elixir
  @impl Riverside
  def authenticate(req) do

    token = req.bearer_token

    case MyAuth.authenticate(token) do

      {:ok, user_id} ->
        session_id = create_random_string()
        state = %{}
        {:ok, user_id, session_id, state}

      # _ -> ...

    end
  end
  ```

  If authentication results in success, return `{:ok, user_id, session_id, state}`.
  You can put any data into `state`, same as you do in `init` in GenServer.
  `session_id` should be random string. You also can return `{:ok, user_id, state}`, and
  Then `session_id` will be generated automatically.

  And `init/3` will be called after successful auth response.

  ### session

  Now I can describe about the `session` parameter included for each callback functions.

  This is a `Riverside.Session.t` struct, and it includes some parameters like `user_id` and `session_id`.

  When you omit to define `authenticate/1`, both `user_id` and `session_id` will be set random value.

  ```elixir
  @impl Riverside
  def handle_message(msg, session, state) do
    # session.user_id
    # session.session_id
  end
  ```

  ## Message and Delivery

  ### Message Format

  If a client sends a simple TEXT frame with JSON format like the following

  ```javascript
  {
    "to": 1111,
    "body": "Hello"
  }
  ```

  You can handle this JSON message as a **Map**.

  ```elixir
  @impl Riverside
  def handle_message(incoming_message, session, state) do

    dest_user_id = incoming_message["to"]
    body         = incoming_message["body"]

    outgoing_message = %{
      "from" => "#{session.user_id}",
      "body" => body,
    }

    deliver_user(dest_user_id, outgoing_message)

    {:ok, session, state}
  end
  ```

  Then the user who is set as destination(user_id == 1111, in this example)
  receives TEXT frame

  ```javascript
  {
    "from": 2222,
    "body": "Hello"
  }
  ```

  This is because `Riverside.Codec.JSON` is set for `codec` config as default.

  ```elixir
  config :my_app, MySocketHandler,
    codec: Riverside.Codec.JSON
  ```

  This codec decodes incoming message, and encodes outgoing message.

  If you want to accept TEXT frames but don't want encode/decode them.
  Should set `Riverside.Codec.RawText`

  ```elixir
  config :my_app, MySocketHandler,
    codec: Riverside.Codec.RawText
  ```

  If you want to accept BINARY frames but don't want encode/decode them.
  Should set `Riverside.Codec.RawBinary`


  ```elixir
  config :my_app, MySocketHandler,
    codec: Riverside.Codec.RawBinary
  ```

  #### Custom Codec

  The fact is that, JSON codec module is written with small amount of code.
  Take a look at the inside.

  ```elixir
  defmodule Riverside.Codec.JSON do

    @behaviour Riverside.Codec

    @impl Riverside.Codec
    def frame_type do
      :text
    end

    @impl Riverside.Codec
    def encode(msg) do
      case Poison.encode(msg) do

        {:ok, value} ->
          {:ok, value}

        {:error, _exception} ->
          {:error, :invalid_message}

      end
    end

    @impl Riverside.Codec
    def decode(data) do
        case Poison.decode(data) do

          {:ok, value} ->
            {:ok, value}

          {:error, _exception} ->
            {:error, :invalid_message}

        end
    end

  end
  ```

  No explanation needed to write your own codec.
  It's too simple.

  ### Delivery

  There is a module named `Riverside.LocalDelivery`.
  With its `deliver/2` function, you can deliver messages to
  sessions connected to the server.

  ```elixir
  def handle_message(msg, session, state) do

    dest_user_id = msg["to"]
    body = msg["body"]

    outgoing = %{
      from: session.user_id,
      body: body,
    }

  　Riverside.LocalDelivery.deliver(
      {:user, dest_user_id},
      {:text, Poison.encode!(outgoing)}
    )

    {:ok, session, state}
  end
  ```

  First argument is a tuple which represents a **destination**,
  and second is a tuple which represents a **frame**.

  **frame** should be `{:text, body}` or `{:binary, body}`. choose proper one.

  OK, let's describe about 3 kinds of destination.

  #### **USER DESTINATION**

  ```elixir
  {:user, user_id}
  ```

  Send message to all the connections for this user.

  Recent trend is `multi device` support.
  One single user may have a multi connections at the same time.

  #### **SESSION DESTINATION**

  ```elixir
  {:session, user_id, session_id}
  ```

  Send message to a specific connection for this user.

  Sometime, this may be a very important feature.
  For instance, **WebRTC-signaling**, **end-to-end encryption**.

  #### **CHANNEL DESTINATION**

  ```elixir
  {:channel, channel_id}
  ```

  Send message to all the members who is belonging to this channel.

  How to join or leave channels? See the example below.

  ```elixir
  def init(session, state) do
     Riverside.LocalDelivery.join_channel("my_channel")
    {:ok, session, state}
  end

  def handle_message(msg, session, state) do
    dest_channel_id = msg["to"]
    body = msg["body"]

    outgoing = %{
      from: session.user_id,
      body: body,
    }

  　Riverside.LocalDelivery.deliver(
      {:channel, dest_channel_id},
      {:text, Poison.encode!(outgoing)}
    )
    {:ok, session, state}
  end

  def terminate(session, state) do
    Riverside.LocalDelivery.leave_channel("my_channel")
    :ok
  end
  ```

  #### Shortcuts for delivery

  If you want to deliver messages from within your handler,
  You don't need to use `Riverside.LocalDelivery` directly.

  Here are handy functions.

  Let's replace LocalDelivery module to handy version.

  ```elixir
  def init(session, state) do
     join_channel("my_channel")
    {:ok, session, state}
  end

  def handle_message(msg, session, state) do
    dest_channel_id = msg["to"]
    body = msg["body"]

    outgoing = %{
      from: session.user_id,
      body: body,
    }
    # same as LocalDelivery.deliver
    # deliver({:channel, dest_channel_id}, {:text, Poison.encode!(outgoing)})

    # handy version, `codec` works on this way, so you don't need to encode by yourself.
  　deliver_channel(dest_channel_id, outgoing)

    # If you want to send message to `user`
    # deliver_user(dest_user_id, outgoing)

    # If you want to send message to `session`
    # deliver_session(dest_user_id, dest_user_session_id, outgoing)

    {:ok, session, state}
  end

  def terminate(session, state) do
    leave_channel("my_channel")
    :ok
  end
  ```

  #### Echo Back

  To deliver message to sender's connection, you can write like following.

  ```elixir
  deliver_me(msg)
  ```

  This is same as

  ```elixir
  deliver_session(session.user_id, session.session_id, msg)
  ```

  #### Close

  Following like can deliver `close` message to specific connection.

  ```elixir
  Riverside.LocalDelivery.close(user_id, session_id)
  ```

  or just `close` function.

  ```elixir
  close()
  ```

  Example

  ```elixir
  def handle_message(msg, session, state) do

    if is_bad_message(msg) do
      close()
    else
      # ...
    end

    {:ok, session, state}
  end
  ```

  ### Scalable Service

  `LocalDelivery` module and its handy shortcuts are just for **local**.
  This works only for communications in a single server.

  If you need to support more scalable service, consider other solutions.
  For example, Redis-PubSub, RabbitMQ, or gnatsd.

  Here is a example with https://github.com/lyokato/roulette
  (HashRing-ed gnatsd cluster client)

  ```elixir
  def init(session, state) do
    with {:ok, _} <- Roulette.sub("user:#{session.user_id}"),
         {:ok, _} <- Roulette.sub("session:#{session.user_id}/#{session.session_id}") do
      {:ok, session, state}
    else
      error ->
        Logger.wran "failed to setup subscription: #{inspect error}"
        {:error, :system_error}
    end
  end

  def handle_message(msg, session, state) do

    to   = msg["to"]
    body = msg["body"]

    outgoing = %{
      from: session.user_id,
      body: body,
    }

    case Roulette.pub("user:#{to}", Poison.encode!(outgoing)) do
      :ok    -> {:ok, session, state}
      :error -> {:error, :system_error}
    end

  end

  def handle_info(:pubsub_message, topic, msg, pid}, session, state) do
    deliver_me(:text, msg)
    {:ok, session, state}
  end

  def terminate(session, state) do
    :ok
  end
  ```

  ## Configurations

  ### child_spec

  ```elixir
  {Riverside, [
    handler: MySocketHandler,
    router: MyRouter,
  ]}
  ```

  |keyword|default value|description|
  |:--|:--|:--|
  |handler|--|Required. Set your own handler module.|
  |router|Riverside.Router|Plug.Router implementation module which provides endpoints other than **ws(s)://**|

  #### config file

  ```elixir
  config :my_app, MySocketHandler,
    port: 3000,
    path: "/my_ws",
    codec: Riverside.Codec.RawBinary,
    max_connections: 10000,
    max_connection_age: :infinity,
    show_debug_logs: false,
    idle_timeout: 120_000,
    reuse_port: false,
    transmission_limit: [
      duration: 2000,
      capacity: 50
    ]
  ```

  |key|default value|description|
  |:--|:--|:--|
  |port|3000|Port number this http server listens.|
  |path|/|Path for WebSocket endpoint.|
  |max_connections|65536|maximum number of connections this server can keep. you also pay attention to a configuration for a number of OS's file descriptors|
  |max_connection_age|:infinity|Force to disconnect a connection if the duration(milliseconds) passed. Then  `terminate/3` will be called with **:over_age** as a reason. if **:infinity** is set, do nothing.|
  |codec|Riverside.Codec.JSON|text/binary frame codec.|
  |show_debug_logs|false|If this flag is true. detailed debug logs will be shown.|
  |transmission_limit|duration:2000, capacity:50| if <:capacity> frames are sent on a connection in <:duration> milliseconds, disconnect it.Then  `terminate/3` will be called with **:too_many_messages** as a reason.|
  |idle_timeout|60000|Disconnect if no event comes on a connection during this duration|
  |reuse_port|false|TCP **SO_REUSEPORT** flag|

  #### Dynamic Port Number

  You may set port number dinamically.

  You can set port number like following.


  ```elixir
  config :my_app, MySocketHandler,
    port: {:system, "MY_PORT", 3000}
  ```

  Then, port number is picked from runtime environment variable "MY_PORT".
  if it doesn't exist, 3000 will be used.

  """

  alias Riverside.AuthRequest
  alias Riverside.Session

  @type terminate_reason ::
          {:normal, :shutdown | :timeout}
          | {:remote, :closed}
          | {:remote, :cow_ws.close_code(), binary}
          | {:error, :badencoding | :badframe | :closed | :too_many_massages | :over_age | atom}

  @callback __handle_authentication__(req :: AuthRequest.t()) ::
              {:ok, Session.user_id(), any}
              | {:ok, Session.user_id(), Session.session_id(), any}
              | {:error, Riverside.AuthError.t()}

  @callback __config__() :: map

  @callback __handle_data__(
              frame_type :: Riverside.Codec.frame_type(),
              message :: binary,
              session :: Session.t(),
              state :: any
            ) ::
              {:ok, Session.t()}
              | {:error, :invalid_message | :unsupported}

  @callback authenticate(req :: AuthRequest.t()) ::
              {:ok, Session.user_id(), any} ::
              {:ok, Session.user_id(), Session.session_id(), any}
              | {:error, Riverside.AuthError.t()}

  @callback init(session :: Session.t(), state :: any) ::
              {:ok, Session.t(), any}
              | {:error, any}

  @callback handle_message(
              message :: any,
              session :: Session.t(),
              state :: any
            ) :: {:ok, Session.t(), any} | {:stop, atom, any}

  @callback handle_info(
              info :: any,
              session :: Session.t(),
              state :: any
            ) :: {:ok, Session.t(), any} | {:stop, atom, any}

  @callback terminate(
              reason :: terminate_reason,
              session :: Session.t(),
              state :: any
            ) :: :ok

  defmacro __using__(opts \\ []) do
    quote location: :keep, bind_quoted: [opts: opts] do
      require Logger

      @behaviour Riverside

      @riverside_config Riverside.Config.load(__MODULE__, opts)

      import Riverside.LocalDelivery,
        only: [
          join_channel: 1,
          leave_channel: 1
        ]

      import Riverside.AuthError,
        only: [
          auth_error_with_code: 1,
          put_auth_error_header: 3,
          put_auth_error_basic_header: 2,
          put_auth_error_bearer_header: 2,
          put_auth_error_bearer_header: 3
        ]

      import Riverside.Session, only: [trap_exit: 2]

      @impl Riverside
      def __config__, do: @riverside_config

      @impl Riverside
      def __handle_authentication__(req) do
        authenticate(req)
      end

      @impl Riverside
      def __handle_data__(frame_type, data, session, state) do
        if @riverside_config.codec.frame_type === frame_type do
          case @riverside_config.codec.decode(data) do
            {:ok, message} ->
              handle_message(message, session, state)

            {:error, _reason} ->
              {:error, :invalid_message}
          end
        else
          if @riverside_config.show_debug_logs do
            Logger.debug(
              "<Riverside.Connection:#{inspect(self())}>(#{session}) unsupported frame type: #{
                frame_type
              }"
            )
          end

          {:error, :unsupported}
        end
      end

      @spec deliver(
              Riverside.LocalDelivery.destination(),
              {Riverside.Codec.frame_type(), binary}
            ) :: :ok | :error
      def deliver(dest, {frame_type, message}) do
        Riverside.LocalDelivery.deliver(dest, {frame_type, message})
        :ok
      end

      @spec deliver(Riverside.LocalDelivery.destination(), any) :: :ok | :error

      def deliver(dest, data) do
        case @riverside_config.codec.encode(data) do
          {:ok, value} ->
            deliver(dest, {@riverside_config.codec.frame_type, value})

          {:error, :invalid_message} ->
            :error
        end
      end

      @spec deliver_user(
              user_id :: Session.user_id(),
              data :: any
            ) :: :ok | :error

      def deliver_user(user_id, data) do
        deliver({:user, user_id}, data)
      end

      @spec deliver_session(
              user_id :: Session.user_id(),
              session_id :: String.t(),
              data :: any
            ) :: :ok | :error
      def deliver_session(user_id, session_id, data) do
        deliver({:session, user_id, session_id}, data)
      end

      @spec deliver_channel(
              channel_id :: any,
              data :: any
            ) :: :ok | :error

      def deliver_channel(channel_id, data) do
        deliver({:channel, channel_id}, data)
      end

      @spec deliver_me(
              frame_type :: Riverside.Codec.frame_type(),
              message :: binary
            ) :: :ok | :error

      def deliver_me(frame_type, message) do
        send(self(), {:deliver, frame_type, message})
        :ok
      end

      @spec deliver_me(any) :: :ok | :error

      def deliver_me(data) do
        case @riverside_config.codec.encode(data) do
          {:ok, value} ->
            deliver_me(@riverside_config.codec.frame_type, value)

          {:error, :invalid_message} ->
            :error
        end
      end

      @spec close() :: no_return
      def close(), do: send(self(), :stop)

      @impl Riverside
      def authenticate(req) do
        user_id = Riverside.IO.Random.bigint()
        session_id = Riverside.IO.Random.hex(20)
        {:ok, user_id, session_id, %{}}
      end

      @impl Riverside
      def init(session, state), do: {:ok, session, state}

      @impl Riverside
      def handle_info(event, session, state), do: {:ok, session, state}

      @impl Riverside
      def handle_message(_msg, session, state), do: {:ok, session, state}

      @impl Riverside
      def terminate(_reason, _session, _state), do: :ok

      defoverridable authenticate: 1,
                     init: 2,
                     handle_info: 3,
                     handle_message: 3,
                     terminate: 3
    end
  end

  def child_spec(args) do
    Riverside.Supervisor.child_spec(args)
  end
end
