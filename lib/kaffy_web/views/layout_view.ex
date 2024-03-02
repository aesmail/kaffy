defmodule KaffyWeb.LayoutView do
  @moduledoc false

  use Phoenix.View,
    root: "lib/kaffy_web/templates",
    namespace: KaffyWeb

  use PhoenixHTMLHelpers

  def get_flash(conn), do: conn.assigns.flash

  def get_flash(conn, key) do
    [mod, func, args] =
      cond do
        Kaffy.Utils.version_match?(:phoenix, "~> 1.7") ->
          [Phoenix.Flash, :get, [conn.assigns.flash, key]]

        true ->
          [Phoenix.Controller, :get_flash, [conn, key]]
      end

    apply(mod, func, args)
  end
end
