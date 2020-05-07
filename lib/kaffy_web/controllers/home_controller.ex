defmodule KaffyWeb.HomeController do
  use Phoenix.Controller, namespace: KaffyWeb
  import Plug.Conn

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
