defmodule Riverside.PeerInfo do

  @type t :: %__MODULE__{address:         :inet.ip_address,
                         port:            :inet.port_number,
                         x_forwarded_for: String.t}

  defstruct address:         nil,
            port:            0,
            x_forwarded_for: nil

  def gather(req) do
    {{address, port}, _} = :cowboy_req.peer(req)
    x_forwarded_for      = parse_x_forwarded_for_header(req)

    %__MODULE__{address:         address,
                port:            port,
                x_forwarded_for: x_forwarded_for}
  end

  defp parse_x_forwarded_for_header(req) do
    case :cowboy_req.parse_header("x-forwarded-for", req) do
      {:ok, [head|_tail], _} -> head
      _                      -> ""
    end
  end

end

defimpl String.Chars, for: Riverside.PeerInfo do

  alias Riverside.PeerInfo

  def to_string(%PeerInfo{address: address, port: port, x_forwarded_for: x_forwarded_for}) do
    "<IP:#{:inet_parse.ntoa(address)}/PORT:#{port}/X-FORWARDED-FOR:#{x_forwarded_for}>"
  end

end
