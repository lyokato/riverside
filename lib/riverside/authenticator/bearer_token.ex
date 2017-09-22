defmodule Riverside.Authenticator.BearerToken do

  @behaviour Riverside.Authenticator.Behaviour

  @alias Riverside.Util.CowboyUtil

  require Logger

  def authenticate(req, opts, f) do

    realm = Keyword.get(opts, "realm", "")

    with {:ok, token}          <- CowboyUtil.bearer_auth_credential(req),
         {:ok, user_id, stash} <- f.({:bearer_token, token}) do

      {:ok, user_id, stash}

    else
      {:error, :invalid_token} ->
        req2 = put_authenticate_header(req, 401, realm, "invalid_token")
        {:error, :unauthorized, req2}

      {:error, :invalid_request} ->
        req2 = put_authenticate_header(req, 400, realm, "invalid_request")
        {:error, :bad_request, req2}

      {:error, :not_found} ->
        req2 = put_authenticate_header(req, 401, realm)
        {:error, :unauthorized, req2}
    end

  end

  defp put_authenticate_header(req, code, realm, reason \\ nil) do
    CowboyUtil.auth_error_response(req, code, "WWW-Authenticate",
      authenticate_header_value(realm, reason))
  end

  defp authenticate_header_value(realm, nil) do
    "Bearer realm=\"#{realm}\""
  end
  defp authenticate_header_value(realm, reason) do
    "Bearer realm=\"#{realm}\" error=\"#{reason}\""
  end

end
