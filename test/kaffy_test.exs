defmodule KaffyTest do
  use ExUnit.Case
  doctest Kaffy
  alias KaffyTest.Schemas.{Person, Pet}
  alias KaffyTest.Admin.PersonAdmin

  test "greets the world" do
    assert Kaffy.hello() == :world
  end

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

  describe "Kaffy.Resource" do
    alias Kaffy.Resource

    test "excluded_fields should return primary keys" do
      assert [:id] == Resource.excluded_fields(Person)
      assert [:id] == Resource.excluded_fields(Pet)
    end

    test "primary_keys/1 should return a list of primary keys" do
      assert [:id] == Resource.primary_keys(Person)
      assert [:id] == Resource.primary_keys(Pet)
    end

    test "kaffy_field_name/2 should return the name of the field" do
      assert "Address" == Resource.kaffy_field_name(nil, :address)
      assert "Created_at" == Resource.kaffy_field_name(nil, :created_at)
      person = %Person{name: "Abdullah"}
      f = {:status, %{name: "Yes"}}
      assert "Yes" == Resource.kaffy_field_name(person, f)
      f = {:status, %{name: fn p -> String.upcase(p.name) end}}
      assert "ABDULLAH" == Resource.kaffy_field_name(person, f)
      f = {:status, %{value: "something"}}
      assert "Status" == Resource.kaffy_field_name(person, f)
    end

    test "kaffy_field_value/2 should return the value of the field" do
      person = %Person{name: "Abdullah"}
      assert "Abdullah" == Resource.kaffy_field_value(person, :name)
      field = {:name, %{value: "Esmail"}}
      assert "Esmail" == Resource.kaffy_field_value(person, field)
      field = {:name, %{value: fn p -> "Mr. #{p.name}" end}}
      assert "Mr. Abdullah" == Resource.kaffy_field_value(person, field)
      field = {:name, %{name: fn p -> "Mr. #{p.name}" end}}
      assert "Abdullah" == Resource.kaffy_field_value(person, field)
    end

    test "fields/1 should return all the fields of a schema without associations" do
      fields = Resource.fields(Person)
      assert is_list(fields)
      assert Enum.all?(fields, fn f -> is_atom(f) end)
      [first | _] = fields
      assert first == :id
      assert length(fields) == 6
    end

    test "associations/1 must return all associations for the schema" do
      associations = Resource.associations(Person)
      assert [:pets] == associations
      pet_assoc = Resource.associations(Pet)
      assert [:person] == pet_assoc
    end

    test "association/1 must return information about the association" do
      person_assoc = Resource.association(Person, :pets)
      assert Ecto.Association.Has == person_assoc.__struct__
      assert person_assoc.cardinality == :many
      assert person_assoc.queryable == Pet

      pet_assoc = Resource.association(Pet, :person)
      assert Ecto.Association.BelongsTo == pet_assoc.__struct__
      assert pet_assoc.cardinality == :one
      assert pet_assoc.queryable == Person
    end

    test "association_schema/2 must return the schema of the association" do
      assert Pet == Resource.association_schema(Person, :pets)
      assert Person == Resource.association_schema(Pet, :person)
    end

    test "form_label/2 should return a label tag" do
      {:safe, label_tag} = Resource.form_label(:user, "My name")
      assert is_list(label_tag)
      label_string = to_string(label_tag)
      assert String.contains?(label_string, "<label")
      assert String.contains?(label_string, "user")
      assert String.contains?(label_string, "My name")
    end
  end

  describe "Kaffy.ResourceAdmin" do
    alias Kaffy.ResourceAdmin

    test "index/1 should return a keyword list of fields and their values" do
      assert Kaffy.Resource.fields(Person) == ResourceAdmin.index(schema: Person)
      custom_index = ResourceAdmin.index(schema: Person, admin: PersonAdmin)
      assert [:name, :married] == Keyword.keys(custom_index)
    end
  end
end
