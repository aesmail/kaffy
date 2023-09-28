ExUnit.start()
Application.put_env(:phoenix, :json_library, Jason)

defmodule KaffyTest.Schemas.Person do
  use Ecto.Schema

  schema "people" do
    field(:name, :string)
    field(:age, :integer)
    field(:married, :boolean, default: false)
    field(:birth_date, :date)
    field(:address, :string)
    has_many(:pets, KaffyTest.Schemas.Pet)
    belongs_to(:company, KaffyTest.Schemas.Company)
  end
end

defmodule KaffyTest.Admin.PersonAdmin do
  def index(_) do
    [
      name: nil,
      married: %{value: fn p -> if p.married, do: "yes", else: "no" end}
    ]
  end
end

defmodule KaffyTest.Schemas.Pet do
  use Ecto.Schema

  schema "pets" do
    field(:name, :string)
    field(:type, :string, default: "feline")
    field(:weight, :decimal)
    belongs_to(:person, KaffyTest.Schemas.Person)
  end
end

defmodule KaffyTest.Schemas.Company do
  use Ecto.Schema

  schema "companies" do
    field(:name, :string)
    has_many(:people, KaffyTest.Schemas.Person)
  end
end

defmodule KaffyTest.Schemas.Owner do
  use Ecto.Schema

  @primary_key false
  schema "owner" do
    field :person_id, :id, primary_key: true
    field :pet_id, :id, primary_key: true
  end
end
