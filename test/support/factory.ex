defmodule KaffyTest.Factory do
  use ExMachina.Ecto, repo: KaffyTest.Repo

  alias KaffyTest.Schemas.Company
  alias KaffyTest.Schemas.Owner
  alias KaffyTest.Schemas.Person
  alias KaffyTest.Schemas.Pet

  def company_factory do
    %Company{name: sequence(:company, &"Company #{&1}")}
  end

  def person_factory do
    age = Enum.random(21..100)
    dob = Date.utc_today() |> Date.add(-age)

    %Person{
      name: sequence(:person, &"Person #{&1}"),
      age: age,
      married: Enum.random([true, false]),
      birth_date: dob,
      address: sequence(:address, &"Address #{&1}"),
      company: build(:company)
    }
  end

  def pet_factory do
    %Pet{
      name: sequence(:pet, &"Pet #{&1}"),
      type: Enum.random(["feline", "canine", "avian"]),
      weight: Decimal.new(Enum.random(1..100)),
      person: build(:person)
    }
  end

  def owner_factory do
    %Owner{}
  end
end
