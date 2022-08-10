defmodule Kaffy.ResourceAdminTest do
  use ExUnit.Case, async: true
  alias Kaffy.ResourceAdmin

  defmodule Cactus do
  end

  defmodule CactusAdmin do
    def plural_name(_), do: "Cacti"
  end

  defmodule Person do
  end

  defmodule PersonAdmin do
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
end
