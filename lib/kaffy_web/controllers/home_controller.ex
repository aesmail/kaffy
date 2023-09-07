defmodule KaffyWeb.HomeController do
  @moduledoc false

  use Phoenix.Controller, namespace: KaffyWeb

  def index(conn, _params) do
    redirect(conn, to: Kaffy.Utils.home_page(conn))
  end

  def dashboard(conn, _params) do
    render(conn, "index.html",
      layout: {KaffyWeb.LayoutView, "app.html"},
      context: :kaffy_dashboard
    )
  end
end
