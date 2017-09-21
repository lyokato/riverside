defmodule Riverside.Authenticator.Default do

  def authenticate(_req, f) do
    f.({:default})
  end

end
