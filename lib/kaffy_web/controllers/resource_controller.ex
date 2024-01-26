defmodule KaffyWeb.ResourceController do
  @moduledoc false

  use Phoenix.Controller, namespace: KaffyWeb
  alias Kaffy.Pagination

  def dashboard(conn, %{"context" => context}) do
    render(conn, "dashboard.html",
      layout: {KaffyWeb.LayoutView, "app.html"},
      context: String.to_existing_atom(context)
    )
  end

  def index(
        conn,
        %{
          "context" => context,
          "resource" => resource,
          "c" => _target_context,
          "r" => _target_resource,
          "pick" => _field
        } = params
      ) do
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        fields = Kaffy.ResourceAdmin.index(my_resource)
        {filtered_count, entries} = Kaffy.ResourceQuery.list_resource(conn, my_resource, params)
        items_per_page = Map.get(params, "limit", "100") |> String.to_integer()
        page = Map.get(params, "page", "1") |> String.to_integer()
        has_next = round(filtered_count / items_per_page) > page
        next_class = if has_next, do: "", else: " disabled"
        has_prev = page >= 2
        prev_class = if has_prev, do: "", else: " disabled"
        list_pages = Pagination.get_pages(page, ceil(filtered_count / items_per_page))

        render(conn, "pick_resource.html",
          layout: {KaffyWeb.LayoutView, "bare.html"},
          context: context,
          resource: resource,
          fields: fields,
          my_resource: my_resource,
          filtered_count: filtered_count,
          page: page,
          has_next_page: has_next,
          next_class: next_class,
          has_prev_page: has_prev,
          prev_class: prev_class,
          list_pages: list_pages,
          entries: entries,
          params: params
        )
    end
  end

  def index(conn, %{"context" => context, "resource" => resource} = params) do
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        fields = Kaffy.ResourceAdmin.index(my_resource)
        {filtered_count, entries} = Kaffy.ResourceQuery.list_resource(conn, my_resource, params)
        items_per_page = Map.get(params, "limit", "100") |> String.to_integer()
        page = Map.get(params, "page", "1") |> String.to_integer()
        has_next = round(filtered_count / items_per_page) > page
        next_class = if has_next, do: "", else: " disabled"
        has_prev = page >= 2
        prev_class = if has_prev, do: "", else: " disabled"
        list_pages = Pagination.get_pages(page, ceil(filtered_count / items_per_page))

        render(conn, "index.html",
          layout: {KaffyWeb.LayoutView, "app.html"},
          context: context,
          resource: resource,
          fields: fields,
          my_resource: my_resource,
          filtered_count: filtered_count,
          page: page,
          has_next_page: has_next,
          next_class: next_class,
          has_prev_page: has_prev,
          prev_class: prev_class,
          list_pages: list_pages,
          entries: entries,
          params: params
        )
    end
  end

  def show(conn, %{"context" => context, "resource" => resource, "id" => id}) do
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)
    schema = my_resource[:schema]
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource)
    can_edit = :edit in Kaffy.ResourceAdmin.default_actions(my_resource)
    can_delete = :delete in Kaffy.ResourceAdmin.default_actions(my_resource)
    form_method = if can_edit or can_delete, do: :put, else: :get

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        if entry = Kaffy.ResourceQuery.fetch_resource(conn, my_resource, id) do
          changeset = Ecto.Changeset.change(entry)

          render(conn, "show.html",
            layout: {KaffyWeb.LayoutView, "app.html"},
            changeset: changeset,
            context: context,
            resource: resource,
            my_resource: my_resource,
            resource_name: resource_name,
            schema: schema,
            entry: entry,
            can_edit: can_edit,
            can_delete: can_delete,
            form_method: form_method
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
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)
    schema = my_resource[:schema]
    params = Kaffy.ResourceParams.decode_map_fields(resource, schema, params)
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource) |> String.capitalize()
    can_edit = :edit in Kaffy.ResourceAdmin.default_actions(my_resource)
    can_delete = :delete in Kaffy.ResourceAdmin.default_actions(my_resource)
    form_method = if can_edit or can_delete, do: :put, else: :get

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        entry = Kaffy.ResourceQuery.fetch_resource(conn, my_resource, id)
        changes = Map.get(params, resource, %{})

        case Kaffy.ResourceCallbacks.update_callbacks(conn, my_resource, entry, changes) do
          {:ok, entry} ->
            conn = put_flash(conn, :success, "#{resource_name} saved successfully")

            save_button = Map.get(params, "submit", "Save")

            case save_button do
              "Save" ->
                conn
                |> put_flash(:success, "#{resource_name} saved successfully")
                |> redirect(
                  to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource)
                )

              "Save and add another" ->
                conn
                |> put_flash(:success, "#{resource_name} saved successfully")
                |> redirect(
                  to: Kaffy.Utils.router().kaffy_resource_path(conn, :new, context, resource)
                )

              "Save and continue editing" ->
                conn
                |> put_flash(:success, "#{resource_name} saved successfully")
                |> redirect_to_resource(context, resource, entry)
            end

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
              entry: entry,
              can_edit: can_edit,
              can_delete: can_delete,
              form_method: form_method
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
              entry: entry,
              can_edit: can_edit,
              can_delete: can_delete,
              form_method: form_method
            )
        end
    end
  end

  def new(conn, %{"context" => context, "resource" => resource}) do
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource)

    with {:permitted, true} <- {:permitted, can_proceed?(my_resource, conn)},
         {:enabled, true} <- {:enabled, is_enabled?(my_resource, :new)} do
      changeset = Kaffy.ResourceAdmin.create_changeset(my_resource, %{}) |> Map.put(:errors, [])

      render(conn, "new.html",
        layout: {KaffyWeb.LayoutView, "app.html"},
        changeset: changeset,
        context: context,
        resource: resource,
        resource_name: resource_name,
        my_resource: my_resource
      )
    else
      {:permitted, false} -> unauthorized_access(conn)
      {:enabled, false} -> not_enabled(conn)
    end
  end

  def create(conn, %{"context" => context, "resource" => resource} = params) do
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)
    params = Kaffy.ResourceParams.decode_map_fields(resource, my_resource[:schema], params)
    changes = Map.get(params, resource, %{})
    resource_name = Kaffy.ResourceAdmin.singular_name(my_resource)

    with {:permitted, true} <- {:permitted, can_proceed?(my_resource, conn)},
         {:enabled, true} <- {:enabled, is_enabled?(my_resource, :new)} do
      case Kaffy.ResourceCallbacks.create_callbacks(conn, my_resource, changes) do
        {:ok, entry} ->
          case Map.get(params, "submit", "Save") do
            "Save" ->
              put_flash(conn, :success, "Created a new #{resource_name} successfully")
              |> redirect(
                to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource)
              )

            "Save and add another" ->
              conn
              |> put_flash(:success, "#{resource_name} saved successfully")
              |> redirect(
                to: Kaffy.Utils.router().kaffy_resource_path(conn, :new, context, resource)
              )

            "Save and continue editing" ->
              put_flash(conn, :success, "Created a new #{resource_name} successfully")
              |> redirect_to_resource(context, resource, entry)
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
    else
      {:permitted, false} -> unauthorized_access(conn)
      {:enabled, false} -> not_enabled(conn)
    end
  end

  def delete(conn, %{"context" => context, "resource" => resource, "id" => id}) do
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)

    case can_proceed?(my_resource, conn) do
      false ->
        unauthorized_access(conn)

      true ->
        entry = Kaffy.ResourceQuery.fetch_resource(conn, my_resource, id)

        case Kaffy.ResourceCallbacks.delete_callbacks(conn, my_resource, entry) do
          :ok ->
            put_flash(conn, :success, "The record was deleted successfully")
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

          {:error, {_entry, error}} when is_binary(error) ->
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
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)
    entry = Kaffy.ResourceQuery.fetch_resource(conn, my_resource, id)
    actions = Kaffy.ResourceAdmin.resource_actions(my_resource, conn)
    action_record = get_action_record(actions, action_key)

    case action_record.action.(conn, entry) do
      {:ok, entry} ->
        conn = put_flash(conn, :success, "Action performed successfully")
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
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)
    ids = Map.get(params, "ids", "") |> String.split(",")
    entries = Kaffy.ResourceQuery.fetch_list(my_resource, ids)
    actions = Kaffy.ResourceAdmin.list_actions(my_resource, conn)
    action_record = get_action_record(actions, action_key)
    kaffy_inputs = Map.get(params, "kaffy-input", %{})

    result =
      case entries do
        {:error, error_msg} ->
          {:error, error_msg}

        entries ->
          case Map.get(action_record, :inputs, []) do
            [] -> action_record.action.(conn, entries)
            _ -> action_record.action.(conn, entries, kaffy_inputs)
          end
      end

    case result do
      :ok ->
        put_flash(conn, :success, "Action performed successfully")
        |> redirect(to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource))

      {:error, error_msg} ->
        put_flash(conn, :error, error_msg)
        |> redirect(to: Kaffy.Utils.router().kaffy_resource_path(conn, :index, context, resource))
    end
  end

  # def export(conn, %{"context" => context, "resource" => resource}) do
  #   my_resource = Kaffy.Utils.get_resource(conn, context, resource)
  # end

  defp can_proceed?(resource, conn) do
    Kaffy.ResourceAdmin.authorized?(resource, conn)
  end

  defp is_enabled?(resource, action) do
    action in Kaffy.ResourceAdmin.default_actions(resource)
  end

  defp unauthorized_access(conn) do
    conn
    |> put_flash(:error, "You are not authorized to access that page")
    |> redirect(to: Kaffy.Utils.router().kaffy_home_path(conn, :index))
  end

  defp not_enabled(conn) do
    conn
    |> put_flash(:error, "This action has been disabled.")
    |> redirect(to: Kaffy.Utils.router().kaffy_home_path(conn, :index))
  end

  defp redirect_to_resource(conn, context, resource, entry) do
    my_resource = Kaffy.Utils.get_resource(conn, context, resource)
    id = Kaffy.ResourceAdmin.serialize_id(my_resource, entry)

    redirect(conn,
      to:
        Kaffy.Utils.router().kaffy_resource_path(
          conn,
          :show,
          context,
          resource,
          id
        )
    )
  end

  # we received actions as map so we actually use strings as keys
  defp get_action_record(actions, action_key) when is_map(actions) and is_binary(action_key) do
    Map.fetch!(actions, action_key)
  end

  # we received actions as Keyword list so action_key needs to be an atom
  defp get_action_record(actions, action_key) when is_list(actions) and is_binary(action_key) do
    action_key = String.to_existing_atom(action_key)
    [action_record] = Keyword.get_values(actions, action_key)
    action_record
  end
end
