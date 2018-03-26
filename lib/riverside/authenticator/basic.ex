defmodule Riverside.Authenticator.Basic do

  @behaviour Riverside.Authenticator.Behaviour

  require Logger

  alias Riverside.Util.CowboyUtil

  def authenticate(req, opts, f) do

    realm = Keyword.get(opts, :realm, "")

    with {:ok, username, password} <- CowboyUtil.basic_auth_credential(req),
         {:ok, user_id, state}     <- f.({:basic, username, password}) do

      {:ok, user_id, state}

    else

      {:error, :invalid_token} ->
        req2 = put_authenticate_header(req, 401, realm)
        {:error, :unauthorized, req2}

      {:error, :invalid_request} ->
        req2 = put_authenticate_header(req, 401, realm)
        {:error, :bad_request, req2}

      {:error, :not_found} ->
        req2 = put_authenticate_header(req, 401, realm)
        {:error, :unauthorized, req2}

      {:error, :server_error} ->
        req2 = CowboyUtil.response_with_code(req, 500)
        {:error, :server_error, req2}

    end

  end

  defp put_authenticate_header(req, code, realm) do
    CowboyUtil.auth_error_response(req, code,
      "WWW-Authenticate", "Basic realm=\"#{realm}\"")
  end

end
