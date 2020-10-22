defmodule Kaffytest.Admin do
  defmodule PersonAdmin do
    def index(_) do
      [
        name: nil,
        married: %{value: fn p -> if p.married, do: "yes", else: "no" end}
      ]
    end
  end
end
