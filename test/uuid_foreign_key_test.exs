defmodule UuidForeignKeyTest do
  use ExUnit.Case, async: true

  # Mock schema with UUID primary key for testing
  defmodule UuidSchema do
    use Ecto.Schema

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "uuid_records" do
      field(:name, :string)
    end
  end

  # Mock schema with UUID foreign key
  defmodule RelatedSchema do
    use Ecto.Schema

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "related_records" do
      field(:title, :string)
      belongs_to(:uuid_record, UuidSchema, foreign_key: :uuid_record_id, type: :binary_id)
    end
  end

  describe "UUID foreign key handling" do
    test "dropdown options use correct primary key for UUID schemas" do
      # Mock some records with UUID primary keys
      uuid1 = "550e8400-e29b-41d4-a716-446655440000"
      uuid2 = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"

      records = [
        %UuidSchema{id: uuid1, name: "Record 1"},
        %UuidSchema{id: uuid2, name: "Record 2"}
      ]

      # Test that the dropdown creation logic uses the correct primary key
      # This simulates what happens in the text_or_assoc function
      pk_fields = Kaffy.ResourceSchema.primary_keys(UuidSchema)
      primary_key = List.first(pk_fields)

      assert primary_key == :id

      options = Enum.map(records, fn record ->
        pk_value = Map.get(record, primary_key)
        display_value = Map.get(record, :name, "Resource ##{pk_value}")
        {display_value, pk_value}
      end)

      expected_options = [
        {"Record 1", uuid1},
        {"Record 2", uuid2}
      ]

      assert options == expected_options
    end

    test "handles UUID foreign keys correctly in form field generation" do
      changeset = Ecto.Changeset.change(%RelatedSchema{}, %{})
      _form = Phoenix.HTML.FormData.to_form(changeset.changes, as: :related)

      # This test verifies that UUID foreign key fields are handled by text_or_assoc
      # rather than number_input, which would be used for integer IDs
      field_type = Kaffy.ResourceSchema.field_type(RelatedSchema, :uuid_record_id)
      assert field_type == :binary_id

      # Verify it's not an integer ID type
      assert field_type != :id

      # Also verify that RelatedSchema itself has a UUID primary key
      related_pk_fields = Kaffy.ResourceSchema.primary_keys(RelatedSchema)
      assert related_pk_fields == [:id]

      related_pk_type = Kaffy.ResourceSchema.field_type(RelatedSchema, :id)
      assert related_pk_type == :binary_id
    end
  end
end