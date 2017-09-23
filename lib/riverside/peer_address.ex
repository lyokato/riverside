defmodule Riverside.PeerAddress do

  alias Riverside.Util.CowboyUtil

  @type t :: %__MODULE__{address:         :inet.ip_address,
                         port:            :inet.port_number,
                         x_forwarded_for: String.t}

  defstruct address:         nil,
            port:            0,
            x_forwarded_for: nil

  def gather(req) do

    {address, port, x_forwarded_for} = CowboyUtil.peer(req)

    %__MODULE__{address:         address,
                port:            port,
                x_forwarded_for: x_forwarded_for}

  end

end

defimpl String.Chars, for: Riverside.PeerAddress do

  alias Riverside.PeerAddress

  def to_string(%PeerAddress{address: address, port: port, x_forwarded_for: x_forwarded_for}) do
    Poison.encode!(%{
      ip: "#{:inet_parse.ntoa(address)}",
      port: port,
      x_forwarded_for: x_forwarded_for
    })
  end

end
