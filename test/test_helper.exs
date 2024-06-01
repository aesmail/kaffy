ExUnit.start()
Application.put_env(:phoenix, :json_library, Jason)
{:ok, _} = Application.ensure_all_started(:ex_machina)

defmodule KaffyTest.Admin.PersonAdmin do
  def index(_) do
    [
      name: nil,
      married: %{value: fn p -> if p.married, do: "yes", else: "no" end}
    ]
  end
end
