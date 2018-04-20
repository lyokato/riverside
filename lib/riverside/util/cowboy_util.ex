defmodule Riverside.Util.CowboyUtil do

  @spec queries(:cowboy_req.req) :: map

  def queries(req) do
    queries = :cowboy_req.parse_qs(req)
    queries |> Map.new(&{elem(&1,0), elem(&1,1)})
  end

  @spec headers(:cowboy_req.req) :: map

  def headers(req) do
    headers = :cowboy_req.headers(req)
    headers |> Map.new(&{elem(&1,0), elem(&1,1)})
  end

  def response(req, code, headers) do
    :cowboy_req.reply(code, headers, req)
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
