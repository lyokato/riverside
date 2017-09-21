defmodule Riverside.Authenticator do

  @type request_type :: :none
                      | :default
                      | {:bearer_token, String.t}
                      | {:basic, String.t}

  @type cred_type :: :default
                   | {:bearer_token, String.t}
                   | {:basic, String.t, String.t}

  @type callback_result :: {:ok, non_neg_integer, map}
    | {:error, :invalid_request | :invalid_token}

  @type auth_result :: {:ok, non_neg_integer, map}
    | {:error, :unauzhorized, :cowboy_req.req}
    | {:error, :bad_request, :cowboy_req.req}

  @type callback_func :: (cred_type -> callback_result)

  defmodule Behaviour do
    @callback authenticate(:cowboy_req.req,
                           Keyword.t,
                           Riverside.Authenticator.callback_func)
      :: Riverside.Authenticator.auth_result
  end

end
