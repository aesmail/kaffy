defmodule KaffyWeb.TaskController do
  @moduledoc false

  use Phoenix.Controller, formats: [html: "View"]

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
