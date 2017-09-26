defmodule Riverside.Authenticator.Default do

  @behaviour Riverside.Authenticator.Behaviour
  alias Riverside.Util.CowboyUtil

  def authenticate(req, _opts, f) do
    with {:ok, user_id, state} <- f.(:default) do
      {:ok, user_id, state}
    else
      {:error, :server_error} ->
        req2 = CowboyUtil.response_with_code(req, 500)
        {:error, :server_error, req2}

      {:error, _reason} ->
        req2 = CowboyUtil.response_with_code(req, 400)
        {:error, :bad_request, req2}
    end
  end

end
