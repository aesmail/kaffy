defmodule KaffyWeb.PageController do
  @moduledoc false

  use Phoenix.Controller, namespace: KaffyWeb

  def index(conn, %{"slug" => slug}) do
    case Kaffy.ResourceAdmin.find_page(conn, slug) do
      nil ->
        conn
        |> put_flash(:error, "The page you are trying to visit does not exist")
        |> redirect(to: Kaffy.Utils.router().kaffy_home_path(conn, :index))

      page ->
        conn
        |> put_layout({KaffyWeb.LayoutView, "app.html"})
        |> put_view(page.view)
        |> render(page.template, Map.get(page, :assigns, []))
    end
  end
end
