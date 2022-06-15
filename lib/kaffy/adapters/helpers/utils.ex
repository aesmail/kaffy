defmodule Kaffy.Adapters.Helpers.Utils do
  def humanize_term(term) do
    term
    |> to_string()
    |> String.split(".")
    |> Enum.at(-1)
    |> Macro.underscore()
    |> String.split("_")
    |> Enum.map(fn s -> String.capitalize(s) end)
    |> Enum.join(" ")
  end
end
