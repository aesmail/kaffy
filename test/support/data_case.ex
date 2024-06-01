defmodule Kaffy.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import KaffyTest.Factory
      import Phoenix.ConnTest

      alias KaffyTest.Repo
    end
  end

  setup tags do
    start_supervised(KaffyTest.Repo)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(KaffyTest.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(KaffyTest.Repo, {:shared, self()})
    end

    :ok
  end
end
