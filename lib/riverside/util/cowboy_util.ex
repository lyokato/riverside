defmodule Riverside.Util.CowboyUtil do

  @spec queries(:cowboy_req.req) :: map

  def queries(req) do
    queries = :cowboy_req.parse_qs(req)
    queries |> Map.new(&{String.to_atom(elem(&1,0)), elem(&1,1)})
  end

  @spec headers(:cowboy_req.req) :: map

  def headers(req) do
    headers = :cowboy_req.headers(req)
    headers |> Map.new(&{String.to_atom(elem(&1,0)), elem(&1,1)})
  end

  @spec auth_error_response(:cowboy_req.req, non_neg_integer, String.t, String.t) :: :cowboy_req.req

  def auth_error_response(req, code, name, value) do
    :cowboy_req.reply(code, %{name => value}, req)
  end

  @spec response_with_code(:cowboy_req.req, non_neg_integer) :: :cowboy_req.req

  def response_with_code(req, code) do
    :cowboy_req.reply(code, %{}, req)
  end

  @spec basic_auth_credential(:cowboy_req.req)
    :: {:ok, String.t, String.t}
     | {:error, :not_found}

  def basic_auth_credential(req) do
    if req.headers["authorization"] == nil do
      {:error, :not_found}
    else
      case String.split(req.headers["authorization"], " ") do
        ["Basic", b64encoded] -> case Base.decode64(b64encoded) do
          {:ok, b64decoded} -> case String.split(b64decoded, ":") do
            [username, password] -> {:ok, username, password}
            _other -> {:error, :not_found}
          end
          _ -> {:error, :not_found}
        end
        _ -> {:error, :not_found}
      end
    end
  end

  @spec bearer_auth_credential(:cowboy_req.req)
    :: {:ok, String.t}
     | {:error, :not_found}

  def bearer_auth_credential(req) do
    if req.headers["authorization"] == nil do
      {:error, :not_found}
    else
      case String.split(req.headers["authorization"], " ") do
        ["Bearer", token] -> {:ok, token}
        _                 -> {:error, :not_found}
      end
    end
  end

  @spec peer(:cowboy_req.req)
    :: {:inet.ip_address, :inet.port_number, String.t}

  def peer(req) do
    {address, port} = :cowboy_req.peer(req)
    {address, port, x_forwarded_for(req)}
  end

  @spec x_forwarded_for(:cowboy_req.req) :: String.t

  def x_forwarded_for(req) do
    case :cowboy_req.parse_header("x-forwarded-for", req) do
      {:ok, [head|_tail], _} -> head
      _                      -> ""
    end
  end

end
