defmodule ActionsTest do
  use ExUnit.Case
  import Phoenix.ConnTest

  import Mock
  alias Phoenix.Controller, as: PhoenixController

  alias KaffyWeb.ResourceController

  defmodule ActionsListAdmin do
    @atom_action :test_action
    @response %{id: "id"}

    def index(_), do: []

    def resource_actions(_conn) do
      [
        {@atom_action,
         %{
           name: "Test Action",
           action: fn _, _ ->
             {:ok, @response}
           end
         }}
      ]
    end

    def list_actions(_conn) do
      [
        {@atom_action,
         %{
           name: "Test Action",
           action: fn _, _, _ ->
             {:ok, @response}
           end
         }}
      ]
    end
  end

  defmodule ActionsMapAdmin do
    @string_action "test_action"
    @response %{id: "id"}

    def index(_), do: []

    def resource_actions(_conn) do
      %{
        @string_action => %{
          name: "Test Action",
          action: fn _, _ ->
            {:ok, @response}
          end
        }
      }
    end

    def list_actions(_conn) do
      %{
        @string_action => %{
          name: "Test Action",
          action: fn _, _, _ ->
            {:ok, @response}
          end
        }
      }
    end
  end

  defmodule ActionsCompositeKeyAdmin do
    @string_action :test_action
    @response %{person_id: 1, pet_id: 1}

    def index(_), do: []

    def resource_actions(_conn) do
      [
        {
          @string_action,
          %{
            name: "Test Action",
            action: fn _, _ ->
              {:ok, @response}
            end
          }
        }
      ]
    end

    def list_actions(_conn) do
      [
        {
          @string_action,
          %{
            name: "Test Action",
            action: fn _, _ ->
              :ok
            end
          }
        }
      ]
    end
  end

  defmodule FakeSchema do
    use Ecto.Schema

    schema "fake_schema" do
    end

    def changeset(fake, _attrs) do
      fake
    end
  end

  defmodule FakeRouter do
    use Phoenix.Router
    use Kaffy.Routes, scope: "/admin"
  end

  setup do
    Application.put_env(:kaffy, :resources, fn _ ->
      [
        list: [
          # a custom name for this context/section.
          name: "list",
          # this line used to be "schemas" in pre v0.9
          resources: [
            test: [schema: FakeSchema, admin: ActionsListAdmin]
          ]
        ],
        map: [
          name: "map",
          resources: [
            test: [schema: FakeSchema, admin: ActionsMapAdmin]
          ]
        ],
        composite: [
          name: "composite",
          resources: [
            test: [schema: KaffyTest.Schemas.Owner, admin: ActionsCompositeKeyAdmin]
          ]
        ]
      ]
    end)

    Application.put_env(:kaffy, :router, FakeRouter)

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> PhoenixController.fetch_flash([])

    [conn: conn]
  end

  test "resource controller accepts list of actions", %{conn: conn} do
    with_mock Kaffy.ResourceQuery, fetch_resource: fn _, _, _ -> %{id: "id"} end do
      result_conn =
        ResourceController.single_action(conn, %{
          "context" => "list",
          "resource" => "test",
          "action_key" => "test_action",
          "id" => "id"
        })

      assert %{"success" => _} = KaffyWeb.LayoutView.get_flash(result_conn)
    end
  end

  test "resource controller accepts map of actions", %{conn: conn} do
    with_mock Kaffy.ResourceQuery, fetch_resource: fn _, _, _ -> %{id: "id"} end do
      result_conn =
        ResourceController.single_action(conn, %{
          "context" => "map",
          "resource" => "test",
          "action_key" => "test_action",
          "id" => "id"
        })

      assert %{"success" => _} = KaffyWeb.LayoutView.get_flash(result_conn)
    end
  end

  test "single action handles composite primary keys", %{conn: conn} do
    with_mock Kaffy.ResourceQuery, fetch_resource: fn _, _, _ -> %{person_id: 1, pet_id: 1} end do
      result_conn =
        ResourceController.single_action(conn, %{
          "context" => "composite",
          "resource" => "test",
          "action_key" => "test_action",
          "id" => "1:1"
        })

      assert %{"success" => _} = KaffyWeb.LayoutView.get_flash(result_conn)
    end
  end

  test "list action handles composite primary keys", %{conn: conn} do
    with_mock Kaffy.ResourceQuery,
      fetch_list: fn _, _ -> [%{person_id: 1, pet_id: 1}, %{person_id: 1, pet_id: 2}] end do
      result_conn =
        ResourceController.list_action(conn, %{
          "context" => "composite",
          "resource" => "test",
          "action_key" => "test_action",
          "id" => "1:1,1:2"
        })

      assert %{"success" => _} = KaffyWeb.LayoutView.get_flash(result_conn)
    end
  end
end
