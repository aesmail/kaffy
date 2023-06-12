defmodule Kaffy.ResourceAdminTest do
  use ExUnit.Case, async: true
  alias Kaffy.ResourceAdmin

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
