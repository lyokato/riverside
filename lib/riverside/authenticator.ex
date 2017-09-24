defmodule Riverside.Authenticator do

  @type request_type :: :default
                      | {:bearer_token, String.t}
                      | {:basic, String.t}

  @type cred_type :: :default
                   | {:bearer_token, String.t}
                   | {:basic, String.t, String.t}

  @type callback_result :: {:ok, Riverside.Session.user_id, any}
    | {:error, :invalid_request | :invalid_token | :server_error }

  @type auth_result :: {:ok, Riverside.Session.user_id, any}
    | {:error, :unauzhorized, :cowboy_req.req}
    | {:error, :bad_request, :cowboy_req.req}
    | {:error, :server_error, :cowboy_req.req}

  @type callback_func :: (cred_type -> callback_result)

  defmodule Behaviour do
    @callback authenticate(:cowboy_req.req,
                           Keyword.t,
                           Riverside.Authenticator.callback_func)
      :: Riverside.Authenticator.auth_result
  end

end
