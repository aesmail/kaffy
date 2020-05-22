defmodule KaffyWeb.TaskController do
  @moduledoc false

  use Phoenix.Controller, namespace: KaffyWeb

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
