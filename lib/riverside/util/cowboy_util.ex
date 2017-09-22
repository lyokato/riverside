defmodule Riverside.Util.CowboyUtil do

  @spec query_map(:cowboy_req.req) :: map

  def query_map(req) do
    {queries, _} = :cowboy_req.qs_vals(req)
    queries |> Map.new(&{String.to_atom(elem(&1,0)), elem(&1,1)})
  end

  @spec auth_error_response(:cowboy_req.req, String.t, String.t) :: :cowboy_req.req

  def auth_error_response(req, code, name, value) do
    {:ok, req2} = :cowboy_req.reply(code, [{name, value}], req)
    req2
  end

  @spec basic_auth_credential(:cowboy_req.req)
    :: {:ok, String.t, String.t}
     | {:error, :not_found}

  def basic_auth_credential(req) do
    case :cowboy_req.parse_header("authorization", req) do
      {:ok, {type, cred}, _} ->
        basic_auth_header_value(String.downcase(type), cred)
      _other ->
        {:error, :not_found}
    end
  end
  defp basic_auth_header_value("basic", {username, password}) do
    {:ok, username, password}
  end
  defp basic_auth_header_value(_type, _cred) do
    {:error, :not_found}
  end

  @spec bearer_auth_credential(:cowboy_req.req)
    :: {:ok, String.t}
     | {:error, :not_found}

  def bearer_auth_credential(req) do
    case :cowboy_req.parse_header("authorization", req) do
      {:ok, {type, cred}, _} ->
        bearer_auth_token(String.downcase(type), cred)
      _other ->
        {:error, :not_found}
    end
  end
  defp bearer_token("bearer", cred) do
    {:ok, cred}
  end
  defp bearer_token(_type, _cred) do
    {:error, :not_found}
  end

end
