defmodule ActionsTest do
  use ExUnit.Case, async: false
  use Phoenix.ConnTest

  import Mock

  alias Phoenix.Controller, as: PhoenixController
  alias KaffyTest.Schemas.Empty
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
            test: [schema: Empty, admin: ActionsListAdmin]
          ]
        ],
        map: [
          name: "map",
          resources: [
            test: [schema: Empty, admin: ActionsMapAdmin]
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

      assert %{"success" => _} = get_flash(result_conn)
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

      assert %{"success" => _} = get_flash(result_conn)
    end
  end

  test "Kaffy.ResourceAdmin.resource_actions/2 performs ordering of actions when provided :order fields" do
    defmodule OrderActions do
      def resource_actions(_) do
        %{
          "two" => %{
            order: 2
          },
          "three" => %{
            order: 3
          },
          "four" => %{
            order: 4
          },
          "one" => %{
            order: 1
          }
        }
      end
    end

    assert [{"one", _}, {"two", _}, {"three", _}, {"four", _}] =
             Kaffy.ResourceAdmin.resource_actions([schema: Empty, admin: OrderActions], %{})
  end

  test "Kaffy.ResourceAdmin.resource_actions/2 raises an error when one action declared :order but other did not" do
    defmodule InvalidOrderActions do
      def resource_actions(_) do
        %{
          "two" => %{},
          "one" => %{
            order: 1
          }
        }
      end
    end

    assert_raise RuntimeError, ~r/:order/, fn ->
      Kaffy.ResourceAdmin.resource_actions([schema: Empty, admin: InvalidOrderActions], %{})
    end
  end

  test "Kaffy.ResourceAdmin.resource_actions/2 allows unordered actions" do
    defmodule NonOrderedActions do
      def resource_actions(_) do
        %{
          "two" => %{},
          "one" => %{}
        }
      end
    end

    assert Kaffy.ResourceAdmin.resource_actions([schema: Empty, admin: NonOrderedActions], %{})
  end
end
