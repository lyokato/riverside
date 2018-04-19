defmodule Riverside.AuthRequest do

  alias Riverside.Util.CowboyUtil

  @type t :: %__MODULE__{
    queries: map,
    headers: map,
    peer:    Riverside.PeerAddress.t
  }

  defstruct queries: nil,
            headers: nil,
            peer:    nil

  @spec new(cowboy_req :: :cowboy_req.req,
            peer       :: Riverside.PeerAddress.t) :: t

  def new(cowboy_req, peer) do

    queries = CowboyUtil.queries(cowboy_req)
    headers = CowboyUtil.headers(cowboy_req)

    %__MODULE__{
      queries: queries,
      headers: headers,
      peer:    peer
    }

  end

  @spec basic(t) :: {String.t, String.t}
  def basic(req) do
    case authorization_header(req) do
      {"basic", value} ->
        case Base.decode64(value) do
          {:ok, b64decoded} -> case String.split(b64decoded, ":") do
            [username, password] -> {username, password}
            _other -> {"", ""}
          end
          _other -> {"", ""}
        end
      _other -> {"", ""}
    end
  end

  @spec bearer(t) :: String.t
  def bearer(req) do
    case authorization_header(req) do
      {"bearer", value} -> value
      _other            -> ""
    end
  end

  defp authorization_header(req) do
    if req.headers["authorization"] == nil do
      {"", ""}
    else
      case String.split(req.headers["authorization"], " ") do
        [type, value] -> {String.downcase(type), value}
        _             -> {"", ""}
      end
    end
  end

end
