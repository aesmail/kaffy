defmodule Kaffy.Routes do
  use Phoenix.Router

  defmacro __using__(options \\ []) do
    scoped = Keyword.get(options, :scope, "/admin")
    pipes = Keyword.get(options, :pipe_through, [:kaffy_browser])

    quote do
      pipeline :kaffy_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
        plug(:fetch_live_flash)
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end

      scope unquote(scoped), KaffyWeb do
        pipe_through(unquote(pipes))

        get("/", HomeController, :index, as: :kaffy_home)
        get("/:context/:resource", ResourceController, :index, as: :kaffy_resource)
        post("/:context/:resource", ResourceController, :create, as: :kaffy_resource)
        get("/:context/:resource/new", ResourceController, :new, as: :kaffy_resource)
        get("/:context/:resource/:id", ResourceController, :show, as: :kaffy_resource)
        put("/:context/:resource/:id", ResourceController, :update, as: :kaffy_resource)
      end
    end
  end
end
