defmodule Kaffy.ResourceQueryTest do
  use Kaffy.DataCase, async: false

  alias Kaffy.ResourceQuery
  alias KaffyTest.Schemas.Pet

  defmodule PetAdmin do
  end

  defmodule WithCustomQueryAdmin do
    def custom_index_query(_conn, _resource, query) do
      query
      |> where([p], p.name == "Fido")
    end
  end

  setup_all do
    Application.put_env(:kaffy, :ecto_repo, KaffyTest.Repo)

    Application.put_env(:kaffy, :resources, fn _ ->
      [
        admin: [
          name: "Pets",
          resources: [
            pets: [
              schema: KaffyTest.Schemas.Pet,
              admin: PetAdmin
            ],
            with_custom_query: [
              schema: KaffyTest.Schemas.Pet,
              admin: WithCustomQueryAdmin
            ]
          ]
        ]
      ]
    end)
  end

  setup do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Phoenix.Controller.fetch_flash([])
      |> Map.put(:query_params, %{})

    [conn: conn]
  end

  describe "list_resource/3" do
    test "returns all resources", %{conn: conn} do
      [pet1 | _pets] = insert_list(3, :pet)
      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")
      assert {3, pets} = ResourceQuery.list_resource(conn, resource, %{})
      assert Enum.any?(pets, fn %Pet{} = pet -> pet.id == pet1.id end)
    end

    test "returns per_page limit", %{conn: conn} do
      pets = insert_list(3, :pet)
      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")
      assert {3, [returned_pet]} = ResourceQuery.list_resource(conn, resource, %{"limit" => "1"})

      pet_ids = Enum.map(pets, & &1.id)
      assert Enum.member?(pet_ids, returned_pet.id)
    end

    test "returns pages", %{conn: conn} do
      pets = insert_list(3, :pet)

      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")

      assert {3, [returned_pet1]} =
               ResourceQuery.list_resource(conn, resource, %{"limit" => "1", "page" => "1"})

      assert {3, [returned_pet2]} =
               ResourceQuery.list_resource(conn, resource, %{"limit" => "1", "page" => "2"})

      assert {3, [returned_pet3]} =
               ResourceQuery.list_resource(conn, resource, %{"limit" => "1", "page" => "3"})

      pet_ids =
        Enum.map(pets, & &1.id)
        |> Enum.sort()

      returned_pet_ids =
        [returned_pet1.id, returned_pet2.id, returned_pet3.id]
        |> Enum.sort()

      assert returned_pet_ids == pet_ids
    end

    test "returns search results", %{conn: conn} do
      insert_list(3, :pet)
      pet = insert(:pet, name: "Fido")
      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")

      assert {1, [returned_pet]} =
               ResourceQuery.list_resource(conn, resource, %{"search" => "Fido"})

      assert returned_pet.id == pet.id
    end

    test "returns no results when search does not match", %{conn: conn} do
      insert_list(3, :pet)
      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")
      assert {0, []} = ResourceQuery.list_resource(conn, resource, %{"search" => "Fido"})
    end

    test "returns filter results", %{conn: conn} do
      insert_list(3, :pet)
      pet = insert(:pet, name: "Fido")
      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")
      conn = Map.put(conn, :query_params, %{"person_id" => pet.person.id})
      assert {1, [returned_pet]} = ResourceQuery.list_resource(conn, resource, %{})
      assert returned_pet.id == pet.id
    end

    test "returns no results when filter does not match", %{conn: conn} do
      insert_list(3, :pet)
      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")
      conn = Map.put(conn, :query_params, %{"person_id" => "0"})
      assert {0, []} = ResourceQuery.list_resource(conn, resource, %{})
    end

    test "returns ordered results", %{conn: conn} do
      pets = insert_list(3, :pet)
      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")
      conn = Map.put(conn, :query_params, %{"_of" => "id", "_ow" => "asc"})
      assert {3, returned_pets} = ResourceQuery.list_resource(conn, resource, %{})
      returned_pet_ids = Enum.map(returned_pets, & &1.id)
      sorted_pet_ids = Enum.sort(Enum.map(pets, & &1.id))
      assert returned_pet_ids == sorted_pet_ids
    end

    test "returns ordered results descending", %{conn: conn} do
      pets = insert_list(3, :pet)
      resource = Kaffy.Utils.get_resource(conn, "admin", "pets")
      conn = Map.put(conn, :query_params, %{"_of" => "id", "_ow" => "desc"})
      assert {3, returned_pets} = ResourceQuery.list_resource(conn, resource, %{})
      returned_pet_ids = Enum.map(returned_pets, & &1.id)
      sorted_pet_ids = Enum.reverse(Enum.sort(Enum.map(pets, & &1.id)))
      assert returned_pet_ids == sorted_pet_ids
    end

    test "returns custom query results and page count", %{conn: conn} do
      insert_list(3, :pet)
      _pet = insert(:pet, name: "Fido")
      resource = Kaffy.Utils.get_resource(conn, "admin", "with_custom_query")
      assert {1, [%Pet{name: "Fido"}]} = ResourceQuery.list_resource(conn, resource, %{})
    end
  end
end
