defmodule KaffyWeb.ResourceController do
  @moduledoc false

  use Phoenix.Controller, namespace: KaffyWeb
  use Phoenix.HTML

  def index(conn, %{
        "context" => context,
        "resource" => resource,
        "c" => _target_context,
        "r" => _target_resource,
        "pick" => _field
      }) do
    my_resource = Kaffy.Utils.get_resource(context, resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        fields = Kaffy.ResourceAdmin.index(my_resource)

        render(conn, "pick_resource.html",
          layout: {KaffyWeb.LayoutView, "bare.html"},
          context: context,
          resource: resource,
          fields: fields,
          my_resource: my_resource
        )
    end
  end

  def index(conn, %{"context" => context, "resource" => resource}) do
    my_resource = Kaffy.Utils.get_resource(context, resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        fields = Kaffy.ResourceAdmin.index(my_resource)

        render(conn, "index.html",
          layout: {KaffyWeb.LayoutView, "app.html"},
          context: context,
          resource: resource,
          fields: fields,
          my_resource: my_resource
        )
    end
  end

  def show(conn, %{"context" => context, "resource" => resource, "id" => id}) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    schema = my_resource[:schema]
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        if entry = Kaffy.ResourceQuery.fetch_resource(my_resource, id) do
          changeset = Ecto.Changeset.change(entry)

          render(conn, "show.html",
            layout: {KaffyWeb.LayoutView, "app.html"},
            changeset: changeset,
            context: context,
            resource: resource,
            my_resource: my_resource,
            resource_name: resource_name,
            schema: schema,
            entry: entry
          )
        else
          put_flash(conn, :error, "The resource you are trying to visit does not exist!")
          |> redirect(
            to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource)
          )
        end
    end
  end

  def update(conn, %{"context" => context, "resource" => resource, "id" => id} = params) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    schema = my_resource[:schema]
    params = Kaffy.ResourceParams.decode_map_fields(resource, schema, params)

    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource) |> String.capitalize()

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        entry = Kaffy.ResourceQuery.fetch_resource(my_resource, id)
        changes = Map.get(params, resource, %{})

        case Kaffy.ResourceCallbacks.update_callbacks(conn, my_resource, entry, changes) do
          {:ok, _entry} ->
            conn = put_flash(conn, :info, "#{resource_name} saved successfully")
            fields = Kaffy.ResourceAdmin.index(my_resource)

            render(conn, "index.html",
              layout: {KaffyWeb.LayoutView, "app.html"},
              context: context,
              resource: resource,
              fields: fields,
              my_resource: my_resource
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            conn =
              put_flash(
                conn,
                :error,
                "A problem occurred while trying to save this #{resource}"
              )

            render(conn, "show.html",
              layout: {KaffyWeb.LayoutView, "app.html"},
              changeset: changeset,
              context: context,
              resource: resource,
              my_resource: my_resource,
              resource_name: resource_name,
              schema: schema,
              entry: entry
            )

          {:error, {entry, error}} when is_binary(error) ->
            conn = put_flash(conn, :error, error)
            changeset = Ecto.Changeset.change(entry)

            render(conn, "show.html",
              layout: {KaffyWeb.LayoutView, "app.html"},
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
  end

  def new(conn, %{"context" => context, "resource" => resource}) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        changeset = Kaffy.ResourceAdmin.create_changeset(my_resource, %{}) |> Map.put(:errors, [])

        render(conn, "new.html",
          layout: {KaffyWeb.LayoutView, "app.html"},
          changeset: changeset,
          context: context,
          resource: resource,
          resource_name: resource_name,
          my_resource: my_resource
        )
    end
  end

  def create(conn, %{"context" => context, "resource" => resource} = params) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    params = Kaffy.ResourceParams.decode_map_fields(resource, my_resource[:schema], params)
    changes = Map.get(params, resource, %{})
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        case Kaffy.ResourceCallbacks.create_callbacks(conn, my_resource, changes) do
          {:ok, entry} ->
            case Map.get(params, "submit") do
              "Save" ->
                put_flash(conn, :info, "Created a new #{resource_name} successfully")
                |> redirect(
                  to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource)
                )

              _ ->
                put_flash(conn, :info, "Created a new #{resource_name} successfully")
                |> redirect(
                  to: Kaffy.Utils.router().kaffy_resource_path(conn, :new, context, resource)
                )
            end

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new.html",
              layout: {KaffyWeb.LayoutView, "app.html"},
              changeset: changeset,
              context: context,
              resource: resource,
              resource_name: resource_name,
              my_resource: my_resource
            )

          {:error, {entry, error}} when is_binary(error) ->
            changeset = Ecto.Changeset.change(entry)

            conn
            |> put_flash(:error, error)
            |> render("new.html",
              layout: {KaffyWeb.LayoutView, "app.html"},
              changeset: changeset,
              context: context,
              resource: resource,
              resource_name: resource_name,
              my_resource: my_resource
            )
        end
    end
  end

  def delete(conn, %{"context" => context, "resource" => resource, "id" => id}) do
    my_resource = Kaffy.Utils.get_resource(context, resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        entry = Kaffy.ResourceQuery.fetch_resource(my_resource, id)

        case Kaffy.ResourceCallbacks.delete_callbacks(conn, my_resource, entry) do
          {:ok, _deleted} ->
            put_flash(conn, :info, "The record was deleted successfully")
            |> redirect(
              to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource)
            )

          {:error, %Ecto.Changeset{} = _changeset} ->
            put_flash(
              conn,
              :error,
              "A database-related issue prevented this record from being deleted."
            )
            |> redirect_to_resource(context, resource, entry)

          {:error, {entry, error}} when is_binary(error) ->
            put_flash(conn, :error, error)
            |> redirect_to_resource(context, resource, entry)
        end
    end
  end

  def single_action(conn, %{
        "context" => context,
        "resource" => resource,
        "id" => id,
        "action_key" => action_key
      }) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    entry = Kaffy.ResourceQuery.fetch_resource(my_resource, id)
    actions = Kaffy.ResourceAdmin.resource_actions(my_resource, conn)
    action_key = String.to_existing_atom(action_key)
    [action_record] = Keyword.get_values(actions, action_key)

    case action_record.action.(conn, entry) do
      {:ok, entry} ->
        conn = put_flash(conn, :info, "Action performed successfully")
        redirect_to_resource(conn, context, resource, entry)

      {:error, _} ->
        conn = put_flash(conn, :error, "A validation error occurred")
        redirect_to_resource(conn, context, resource, entry)

      {:error, _, error_msg} ->
        conn = put_flash(conn, :error, error_msg)
        redirect_to_resource(conn, context, resource, entry)
    end
  end

  def list_action(
        conn,
        %{"context" => context, "resource" => resource, "action_key" => action_key} = params
      ) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    action_key = String.to_existing_atom(action_key)
    ids = Map.get(params, "ids", "") |> String.split(",")
    entries = Kaffy.ResourceQuery.fetch_list(my_resource, ids)
    actions = Kaffy.ResourceAdmin.list_actions(my_resource, conn)
    [action_record] = Keyword.get_values(actions, action_key)

    case action_record.action.(conn, entries) do
      :ok ->
        put_flash(conn, :info, "Action performed successfully")
        |> redirect(to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource))

      {:error, error_msg} ->
        put_flash(conn, :error, error_msg)
        |> redirect(to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource))
    end
  end

  # def export(conn, %{"context" => context, "resource" => resource}) do
  #   my_resource = Kaffy.Utils.get_resource(context, resource)
  # end

  def api(conn, %{"context" => context, "resource" => resource} = params) do
    my_resource = Kaffy.Utils.get_resource(context, resource)
    fields = Kaffy.ResourceAdmin.index(my_resource)

    {filtered_count, entries} = Kaffy.ResourceQuery.list_resource(my_resource, params)

    records =
      Enum.map(entries, fn entry ->
        rows =
          Enum.reduce(fields, [], fn field, e ->
            field_value = Kaffy.ResourceSchema.kaffy_field_value(entry, field)
            [field_value | e]
          end)
          |> Enum.reverse()

        [first | rest] = rows

        {:safe, first} =
          link(first,
            to: Kaffy.Utils.router().kaffy_resource_path(conn, :show, context, resource, entry.id)
          )

        first = to_string(first)

        [first | rest]
        |> Enum.with_index()
        |> Enum.map(fn {k, v} -> {to_string(v), k} end)
        |> Enum.into(%{})
        |> Map.put("DT_RowId", entry.id)
      end)

    columns =
      Enum.map(fields, fn
        {f, _} -> %{name: f}
        f -> %{name: f}
      end)

    total_count = Kaffy.ResourceQuery.total_count(my_resource)

    final_result = %{
      raw: Map.get(params, "raw", "0") |> String.to_integer(),
      recordsTotal: total_count,
      columnDefs: columns,
      recordsFiltered: filtered_count,
      data: records
    }

    json(conn, final_result)
  end

  defp can_proceed?(resource, conn) do
    Kaffy.ResourceAdmin.authorized?(resource, conn)
  end

  defp unauthorized_access(conn) do
    conn
    |> put_flash(:error, "You are not authorized to access that page")
    |> redirect(to: Kaffy.Utils.router().kaffy_home_path(conn, :index))
  end

  defp redirect_to_resource(conn, context, resource, entry) do
    redirect(conn,
      to:
        Kaffy.Utils.router().kaffy_resource_path(
          conn,
          :show,
          context,
          resource,
          entry.id
        )
    )
  end
end
