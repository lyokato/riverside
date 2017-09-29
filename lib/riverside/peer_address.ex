defmodule Riverside.PeerAddress do

  @moduledoc ~S"""
  Represents a peer's address

  This data has following three field

  * address
  * port
  * x_forwarded_for

  """

  alias Riverside.Util.CowboyUtil

  @type t :: %__MODULE__{address: String.t,
                         port: :inet.port_number,
                         x_forwarded_for: String.t}

  defstruct address: nil,
            port: 0,
            x_forwarded_for: nil

  @doc ~S"""
  Pick a peer's address from a cowboy request.
  """

  @spec gather(:cowboy_req.req) :: t

  def gather(req) do

    {address, port, x_forwarded_for} = CowboyUtil.peer(req)

    %__MODULE__{address: :inet_parse.ntoa(address),
                port: port,
                x_forwarded_for: x_forwarded_for}

  end

end

defimpl String.Chars, for: Riverside.PeerAddress do

  alias Riverside.PeerAddress

  def to_string(%PeerAddress{address: address, port: port, x_forwarded_for: x_forwarded_for}) do
    Poison.encode!(%{
      ip: address,
      port: port,
      x_forwarded_for: x_forwarded_for
    })
  end

end
