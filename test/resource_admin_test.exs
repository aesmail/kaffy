defmodule Kaffy.ResourceAdminTest do
  use ExUnit.Case, async: true
  alias Kaffy.ResourceAdmin
  alias KaffyTest.Schemas.{Owner, Pet}

  defmodule Cactus do
  end

  defmodule CactusAdmin do
    def plural_name(_), do: "Cacti"
    def index_description(_), do: {:safe, "Person Admin <b>Description</b>"}
  end

  defmodule Person do
  end

  defmodule PersonAdmin do
    def index_description(_), do: "Person Admin Description"
  end

  defmodule PetAdmin do
  end

  defmodule OwnerAdmin do
  end

  defmodule OwnerETFAdmin do
    def serialize_id(_schema, owner) do
      {owner.person_id, owner.pet_id}
      |> :erlang.term_to_binary()
      |> Base.url_encode64(padding: false)
    end

    def deserialize_id(_schema, serialized_id) do
      {person_id, pet_id} = serialized_id
      |> Base.url_decode64!(padding: false)
      |> :erlang.binary_to_term()

      [person_id: person_id, pet_id: pet_id]
    end
  end

  defmodule Nested.Node do
  end

  defmodule Nested.NodeAdmin do
  end

  defmodule NestedNodeAdmin do
    def singular_name(_), do: "NestedNode"
  end

  describe "plural_name/1" do
    test "pluralize standard noun" do
      assert ResourceAdmin.plural_name(schema: Nested.Node, admin: Nested.NodeAdmin) == "Nodes"
    end

    test "pluralize using non-standard singular phrase" do
      assert ResourceAdmin.plural_name(schema: Nested.Node, admin: NestedNodeAdmin) ==
               "NestedNodes"
    end

    test "use custom plural name defined as function in admin" do
      assert ResourceAdmin.plural_name(schema: Cactus, admin: CactusAdmin) == "Cacti"
    end

    test "use non-standard plural form" do
      assert ResourceAdmin.plural_name(schema: Person, admin: PersonAdmin) == "People"
    end
  end

  describe "serialize_id/2" do
    test "serialize standard id" do
      assert ResourceAdmin.serialize_id([schema: Pet, admin: PetAdmin], %{id: 1}) == "1"
    end

    test "serialize composite id" do
      assert ResourceAdmin.serialize_id([schema: Owner, admin: OwnerAdmin], %{person_id: 1, pet_id: 2}) == "1:2"
    end

    test "custom serialization of composite key" do
      assert ResourceAdmin.serialize_id([schema: Owner, admin: OwnerETFAdmin], %{person_id: 1, pet_id: 2}) == "g2gCYQFhAg"
    end
  end

  describe "deserialize_id/2" do
    test "deserialize standard id" do
      assert ResourceAdmin.deserialize_id([schema: Pet, admin: PetAdmin], "1") == [id: "1"]
    end

    test "deserialize composite id" do
      assert ResourceAdmin.deserialize_id([schema: Owner, admin: OwnerAdmin], "1:2") == [person_id: "1", pet_id: "2"]
    end

    test "custom deserialization of composite key" do
      assert ResourceAdmin.deserialize_id([schema: Owner, admin: OwnerETFAdmin], "g2gCYQFhAg") == [person_id: 1, pet_id: 2]
    end
  end
  
  describe "index_description/1" do
    test "nil if index_description is not defined as function in admin" do
      refute ResourceAdmin.index_description(schema: Nested.Node, admin: NestedNodeAdmin)
    end

    test "string if index_description is defined as function in admin" do
      assert ResourceAdmin.index_description(schema: Person, admin: PersonAdmin) ==
               "Person Admin Description"
    end

    test "{:safe, html} if index_description is defined as function in admin" do
      assert ResourceAdmin.index_description(schema: Cactus, admin: CactusAdmin) ==
               {:safe, "Person Admin <b>Description</b>"}
    end
  end
end
