defmodule KaffyWeb.LayoutView do
  @moduledoc false

  use Phoenix.View,
    root: "lib/kaffy_web/templates",
    namespace: KaffyWeb

  import Phoenix.Controller, only: [get_flash: 2]
  use Phoenix.HTML
end
