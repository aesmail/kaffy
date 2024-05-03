defmodule KaffyTest.Repo.Migrations.CreateTestSchemas do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add(:name, :string)
    end

    create table(:people) do
      add(:name, :string)
      add(:age, :integer)
      add(:married, :boolean, default: false)
      add(:birth_date, :date)
      add(:address, :string)
      add(:company_id, references(:companies, on_delete: :nothing))
    end

    create table(:pets) do
      add(:name, :string)
      add(:type, :string, default: "feline")
      add(:weight, :decimal)
      add(:person_id, references(:people, on_delete: :nothing))
    end

    create table(:owner, primary_key: false) do
      add(:person_id, references(:people, on_delete: :nothing))
      add(:pet_id, references(:pets, on_delete: :nothing))
    end
  end
end
