defmodule Riverside.Router do
  @moduledoc """
  Default Router module
  """

  use Plug.Router

  plug(Plug.Static,
    at: "/",
    from: :riverside,
    only: ~w(favicon.ico robots.txt)
  )

  plug(:match)
  plug(:dispatch)

  # just for health check
  get "/health" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "OK")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
