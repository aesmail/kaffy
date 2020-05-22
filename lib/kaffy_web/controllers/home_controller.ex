defmodule KaffyWeb.HomeController do
  @moduledoc false

  use Phoenix.Controller, namespace: KaffyWeb

  def index(conn, _params) do
    render(conn, "index.html", layout: {KaffyWeb.LayoutView, "app.html"})
  end
end
