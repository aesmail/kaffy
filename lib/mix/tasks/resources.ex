defmodule Mix.Tasks.Kaffy.Resources do
  use Mix.Task

  @shortdoc "Display the auto-detected schemas and admin modules for Kaffy."
  @requirements ["app.config"]

  def run(_args) do
    Kaffy.Utils.setup_resources()
    |> IO.inspect()
  end
end
