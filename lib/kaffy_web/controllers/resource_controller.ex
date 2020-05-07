defmodule KaffyWeb.ResourceController do
  use Phoenix.Controller, namespace: KaffyWeb

  def index(conn, %{"context" => context, "resource" => resource} = params) do
    IO.inspect(conn)
    my_resource = Kaffy.Utils.get_resource(context, resource)
    schema = my_resource[:schema]

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        fields = Kaffy.ResourceAdmin.index(my_resource)
        entries = Kaffy.ResourceQuery.list_resource(my_resource, params)
        total_pages = Kaffy.ResourceQuery.total_pages(my_resource, params)
        limit = Map.get(params, "limit", "100") |> String.to_integer()
        page = Map.get(params, "page", "1") |> String.to_integer()

        render(conn, "index.html",
          context: context,
          resource: resource,
          entries: entries,
          schema: schema,
          fields: fields,
          my_resource: my_resource,
          limit: limit,
          page: page,
          total_pages: total_pages
        )
    end
  end

  def show(conn, %{"context" => context, "resource" => resource, "id" => id}) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    schema = my_resource[:schema]
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource) |> String.capitalize()

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        entry = Kaffy.ResourceQuery.fetch_resource(my_resource, id)
        changeset = Ecto.Changeset.change(entry)
        IO.inspect(changeset)

        render(conn, "show.html",
          changeset: changeset,
          context: context,
          resource: resource,
          my_resource: my_resource,
          resource_name: resource_name,
          schema: schema,
          entry: entry
        )
    end
  end

  def update(conn, %{"context" => context, "resource" => resource, "id" => id} = params) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    schema = my_resource[:schema]

    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource) |> String.capitalize()

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        entry = Kaffy.ResourceQuery.fetch_resource(my_resource, id)
        changes = Map.get(params, resource, %{})

        result =
          Kaffy.ResourceAdmin.update_changeset(my_resource, entry, changes)
          |> Kaffy.Utils.repo().update()

        {conn, changeset} =
          case result do
            {:ok, entry} ->
              changeset = Ecto.Changeset.change(entry)
              conn = put_flash(conn, :info, "Saved #{resource} successfully")
              {conn, changeset}

            {:error, changeset} ->
              conn =
                put_flash(
                  conn,
                  :error,
                  "A problem occurred while trying to save this #{resource}"
                )

              {conn, changeset}
          end

        render(conn, "show.html",
          changeset: changeset,
          context: context,
          resource: resource,
          my_resource: my_resource,
          resource_name: resource_name,
          schema: schema,
          entry: entry
        )
    end
  end

  def new(conn, %{"context" => context, "resource" => resource}) do
    my_resource = Kaffy.Utils.get_resource(context, resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        changeset = Ecto.Changeset.change(my_resource[:schema].__struct__)

        render(conn, "new.html",
          changeset: changeset,
          context: context,
          resource: resource,
          my_resource: my_resource
        )
    end
  end

  def create(conn, %{"context" => context, "resource" => resource} = params) do
    changes = Map.get(params, resource, %{})
    my_resource = Kaffy.Utils.get_resource(context, resource)
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        changeset = Kaffy.ResourceAdmin.create_changeset(my_resource, changes)
        IO.inspect(changeset)

        case Kaffy.Utils.repo().insert(changeset) do
          {:ok, entry} ->
            put_flash(conn, :info, "Created a new #{resource_name} successfully")
            |> redirect(
              to:
                Kaffy.Utils.router().kaffy_resource_path(conn, :show, context, resource, entry.id)
            )

          {:error, changeset} ->
            render(conn, "new.html",
              changeset: changeset,
              context: context,
              resource: resource,
              my_resource: my_resource
            )
        end
    end
  end

  defp can_proceed?(resource, conn) do
    Kaffy.ResourceAdmin.authorized?(resource, conn)
  end

  defp unauthorized_access(conn) do
    conn
    |> put_flash(:error, "You are not authorized to access that page")
    |> redirect(to: Kaffy.Utils.router().kaffy_home_path(conn, :index))
  end
end
