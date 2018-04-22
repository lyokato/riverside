defmodule Riverside.AuthError do

  @type t :: %__MODULE__{
    code:    pos_integer,
    headers: map
  }

  defstruct code: 401, headers: %{}

  def auth_error_with_code(code \\ 401) do
    %__MODULE__{
      code:    code,
      headers: %{}
    }
  end

  def put_auth_error_header(err, type, value) do
    update_in(err.headers, fn headers -> Map.put(headers, type, value) end)
  end

  def put_auth_error_basic_header(err, realm) do
    put_auth_error_header(err,
                          "WWW-Authenticate",
                          "Basic realm=\"#{realm}\"")
  end

  def put_auth_error_bearer_header(err, realm, error \\ nil) do
    if error != nil do
      put_auth_error_header(err,
                            "WWW-Authenticate",
                            "Bearer realm=\"#{realm}\" error=\"#{error}\"")
    else
      put_auth_error_header(err,
                            "WWW-Authenticate",
                            "Bearer realm=\"#{realm}\"")
    end
  end

end
