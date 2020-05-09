defmodule KaffyWeb.HomeController do
  use Phoenix.Controller, namespace: KaffyWeb

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
