defmodule KaffyTest do
  use ExUnit.Case

  alias KaffyTest.Schemas.{Company, Person, Pet, Owner}

  test "creating a person" do
    person = %Person{}
    assert is_nil(person.name)
    assert person.married == false
  end

  test "creating a pet" do
    pet = %Pet{}
    assert pet.type == "feline"
    assert is_nil(pet.name)
  end

  describe "Kaffy.ResourceSchema" do
    alias Kaffy.ResourceSchema

    test "excluded_fields should return primary keys" do
      assert [:id] == ResourceSchema.excluded_fields(Person)
      assert [:id] == ResourceSchema.excluded_fields(Pet)
    end

    test "primary_key/1 should return a primary key" do
      assert [:id] == ResourceSchema.primary_keys(Person)
      assert [:id] == ResourceSchema.primary_keys(Pet)
    end

    test "primary_key/1 should return a composite key" do
      assert [:person_id, :pet_id] == ResourceSchema.primary_keys(Owner)
    end

    test "kaffy_field_name/2 should return the name of the field" do
      assert "Address" == ResourceSchema.kaffy_field_name(nil, :address)
      assert "Created At" == ResourceSchema.kaffy_field_name(nil, :created_at)
      person = %Person{name: "Abdullah"}
      f = {:status, %{name: "Yes"}}
      assert "Yes" == ResourceSchema.kaffy_field_name(person, f)
      f = {:status, %{name: fn p -> String.upcase(p.name) end}}
      assert "ABDULLAH" == ResourceSchema.kaffy_field_name(person, f)
      f = {:status, %{value: "something"}}
      assert "Status" == ResourceSchema.kaffy_field_name(person, f)
    end

    test "kaffy_field_value/2 should return the value of the field" do
      person = %Person{name: "Abdullah"}
      assert "Abdullah" == ResourceSchema.kaffy_field_value(person, :name)
      field = {:name, %{value: "Esmail"}}
      assert "Esmail" == ResourceSchema.kaffy_field_value(nil, person, field)
      field = {:name, %{value: fn p -> "Mr. #{p.name}" end}}
      assert "Mr. Abdullah" == ResourceSchema.kaffy_field_value(nil, person, field)
      field = {:name, %{name: fn p -> "Mr. #{p.name}" end}}
      assert "Abdullah" == ResourceSchema.kaffy_field_value(nil, person, field)
    end

    test "kaffy_field_value/3 should handle preloaded structs with a custom function" do
      person = %Person{company: %Company{name: "Dashbit"}}

      options = {:company, %{name: "Company", value: fn p -> p.company.name end}}
      assert "Dashbit" == ResourceSchema.kaffy_field_value(%{}, person, options)
    end

    test "associations/1 must return all associations for the schema" do
      associations = ResourceSchema.associations(Person)
      assert [:pets, :company] == associations
      pet_assoc = ResourceSchema.associations(Pet)
      assert [:person] == pet_assoc
    end

    test "association/1 must return information about the association" do
      person_assoc = ResourceSchema.association(Person, :pets)
      assert Ecto.Association.Has == person_assoc.__struct__
      assert person_assoc.cardinality == :many
      assert person_assoc.queryable == Pet

      pet_assoc = ResourceSchema.association(Pet, :person)
      assert Ecto.Association.BelongsTo == pet_assoc.__struct__
      assert pet_assoc.cardinality == :one
      assert pet_assoc.queryable == Person
    end

    test "association_schema/2 must return the schema of the association" do
      assert Pet == ResourceSchema.association_schema(Person, :pets)
      assert Person == ResourceSchema.association_schema(Pet, :person)
    end
  end

  describe "Kaffy.ResourceAdmin" do
    # alias Kaffy.ResourceAdmin

    # [Qizot] I don't know if this test should be valid anymore if associations are allowed
    # test "index/1 should return a keyword list of fields and their values" do
    #   assert Kaffy.ResourceSchema.fields(Person) == ResourceAdmin.index(schema: Person)
    #   custom_index = ResourceAdmin.index(schema: Person, admin: PersonAdmin)
    #   assert [:name, :married] == Keyword.keys(custom_index)
    # end
  end
end
