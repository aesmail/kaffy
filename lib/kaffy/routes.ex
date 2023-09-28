defmodule Kaffy.Routes do
  @moduledoc """
  Kaffy.Routes must be "used" in your Phoenix routes:

  ```elixir
  use Kaffy.Routes, scope: "/admin", pipe_through: [:browser, :authenticate]
  ```

  `:scope` defaults to `"/admin"`

  `:pipe_through` defaults to kaffy's `[:kaffy_browser]`
  """

  # use Phoenix.Router

  defmacro __using__(options \\ []) do
    scoped = Keyword.get(options, :scope, "/admin")
    custom_pipes = Keyword.get(options, :pipe_through, [])
    pipes = [:kaffy_browser] ++ custom_pipes

    quote do
      pipeline :kaffy_browser do
        plug(:accepts, ["html", "json"])
        plug(:fetch_session)
        plug(:fetch_flash)
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
        plug(:put_root_layout, {KaffyWeb.LayoutView, :root})
      end

      scope unquote(scoped), KaffyWeb do
        pipe_through(unquote(pipes))

        get("/", HomeController, :index, as: :kaffy_home)
        get("/dashboard", HomeController, :dashboard, as: :kaffy_dashboard)
        get("/tasks", TaskController, :index, as: :kaffy_task)
        get("/p/:slug", PageController, :index, as: :kaffy_page)

        if Kaffy.Utils.show_context_dashboards?() do
          get("/:context", ResourceController, :dashboard, as: :kaffy_context_dashboard)
        end

        get("/:context/:resource", ResourceController, :index, as: :kaffy_resource)
        post("/:context/:resource", ResourceController, :create, as: :kaffy_resource)

        post("/:context/:resource/:id/action/:action_key", ResourceController, :single_action,
          as: :kaffy_resource
        )

        post("/:context/:resource/action/:action_key", ResourceController, :list_action,
          as: :kaffy_resource
        )

        get("/:context/:resource/new", ResourceController, :new, as: :kaffy_resource)
        get("/:context/:resource/:id", ResourceController, :show, as: :kaffy_resource)
        put("/:context/:resource/:id", ResourceController, :update, as: :kaffy_resource)
        delete("/:context/:resource/:id", ResourceController, :delete, as: :kaffy_resource)

        get("/kaffy/api/:context/:resource", ResourceController, :api, as: :kaffy_api_resource)
      end
    end
  end
end
