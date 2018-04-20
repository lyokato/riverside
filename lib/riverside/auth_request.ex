defmodule Riverside.AuthRequest do

  alias Riverside.Util.CowboyUtil

  @type basic_credential :: {String.t, String.t}

  @type t :: %__MODULE__{
    queries:      map,
    headers:      map,
    peer:         Riverside.PeerAddress.t,
    basic:        basic_credential,
    bearer_token: String.t
  }

  defstruct queries:      %{},
            headers:      %{},
            peer:         nil,
            basic:        {"", ""},
            bearer_token: ""

  @spec new(cowboy_req :: :cowboy_req.req,
            peer       :: Riverside.PeerAddress.t) :: t

  def new(cowboy_req, peer) do

    queries = CowboyUtil.queries(cowboy_req)
    headers = CowboyUtil.headers(cowboy_req)

    %__MODULE__{
      queries:      queries,
      headers:      headers,
      peer:         peer,
      basic:        basic(headers),
      bearer_token: bearer_token(headers),
    }

  end

  defp basic(headers) do
    case authorization_header(headers) do
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

  defp bearer_token(headers) do
    case authorization_header(headers) do
      {"bearer", value} -> value
      _other            -> ""
    end
  end

  defp authorization_header(headers) do
    if headers["authorization"] == nil do
      {"", ""}
    else
      case String.split(headers["authorization"], " ") do
        [type, value] -> {String.downcase(type), value}
        _             -> {"", ""}
      end
    end
  end

end
