defmodule Riverside.Authenticator.BearerToken do

  require Logger

  def authenticate(req, realm, f) do
    with {:ok, token}          <- parse_authorization_header(req),
         {:ok, user_id, stash} <- f.({:bearer_token, token}) do

      {:ok, user_id, stash}

    else
      {:error, :invalid_token} ->
        req2 = put_authenticate_header(req, realm, 401, "invalid_token")
        {:error, :unauthorized, req2}

      {:error, :invalid_request} ->
        req2 = put_authenticate_header(req, realm, 400, "invalid_request")
        {:error, :bad_request, req2}

      {:error, :authorization_header_not_found} ->
        req2 = put_authenticate_header(req, realm, 401)
        {:error, :unauthorized, req2}
    end

  end

  defp parse_authorization_header(req) do
    case :cowboy_req.parse_header("authorization", req) do

      {:ok, {type, cred}, _} ->
        bearer_token(String.downcase(type), cred)

      _other ->
        Logger.info("authorization header not found")
        {:error, :authorization_header_not_found}
    end
  end

  defp bearer_token("bearer", cred) do
    {:ok, cred}
  end
  defp bearer_token(_type, _cred) do
    Logger.debug("authorization header is not for Bearer token")
    {:error, :bad_request}
  end

  defp put_authenticate_header(req, realm, code, reason \\ nil) do
    {:ok, req2} = :cowboy_req.reply(code,
      [{"WWW-Authenticate", authenticate_header_value(realm, reason)}],
      req)
    req2
  end

  defp authenticate_header_value(realm, nil) do
    "Bearer realm=\"#{realm}\""
  end
  defp authenticate_header_value(realm, reason) do
    "Bearer realm=\"#{realm}\" error=\"#{reason}\""
  end

end
