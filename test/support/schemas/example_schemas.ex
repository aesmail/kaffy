defmodule KaffyTest.Schemas do
  defmodule Pet do
    use Ecto.Schema

    schema "pets" do
      field(:name, :string)
      field(:type, :string, default: "feline")
      field(:weight, :decimal)
      belongs_to(:person, KaffyTest.Schemas.Person)
    end
  end

  defmodule Person do
    use Ecto.Schema

    schema "people" do
      field(:name, :string)
      field(:age, :integer)
      field(:married, :boolean, default: false)
      field(:birth_date, :date)
      field(:address, :string)
      has_many(:pets, KaffyTest.Schemas.Pet)
    end
  end

  defmodule Empty do
    use Ecto.Schema

    schema "empty" do
    end
  end
end
