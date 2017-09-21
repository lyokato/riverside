defmodule Riverside.Authenticator.Basic do

  @behaviour Riverside.Authenticator.Behaviour

  require Logger

  def authenticate(req, opts, f) do

    realm = Keyword.get(opts, "realm", "")

    with {:ok, username, password} <- parse_authorization_header(req),
         {:ok, user_id, stash}     <- f.({:basic, username, password}) do

      {:ok, user_id, stash}

    else

      {:error, :invalid_token} ->
        req2 = put_authenticate_header(req, realm, 401)
        {:error, :unauthorized, req2}

      {:error, :invalid_request} ->
        req2 = put_authenticate_header(req, realm, 400)
        {:error, :bad_request, req2}

      {:error, :authorization_header_not_found} ->
        req2 = put_authenticate_header(req, realm, 401)
        {:error, :unauthorized, req2}

    end

  end

  defp parse_authorization_header(req) do
    case :cowboy_req.parse_header("authorization", req) do

      {:ok, {type, cred}, _} ->
        get_username_and_password(String.downcase(type), cred)

      _other ->
        Logger.info("authorization header not found")
        {:error, :authorization_header_not_found}
    end
  end

  defp get_username_and_password("basic", {username, password}) do
    {:ok, username, password}
  end
  defp get_username_and_password(_type, _cred) do
    Logger.debug("authorization header is not for Basic auth")
    {:error, :bad_request}
  end

  defp put_authenticate_header(req, realm, code) do
    {:ok, req2} = :cowboy_req.reply(code,
      [{"WWW-Authenticate", "Basic realm=\"#{realm}\""}],
      req)
    req2
  end


end
