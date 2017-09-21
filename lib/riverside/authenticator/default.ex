defmodule Riverside.Authenticator.Default do

  @behaviour Riverside.Authenticator.Behaviour

  def authenticate(_req, _opts, f) do
    f.({:default})
  end

end
