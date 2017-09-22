defmodule Riverside.PeerInfo do

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

defimpl String.Chars, for: Riverside.PeerInfo do

  alias Riverside.PeerInfo

  def to_string(%PeerInfo{address: address, port: port, x_forwarded_for: x_forwarded_for}) do
    "<IP:#{:inet_parse.ntoa(address)}/PORT:#{port}/X-FORWARDED-FOR:#{x_forwarded_for}>"
  end

end
