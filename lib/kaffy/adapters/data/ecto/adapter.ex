defmodule Kaffy.Adapters.Data.Ecto.Adapter do
  alias Kaffy.Adapters.Data.DataProtocol
  alias Kaffy.Adapters.Helpers.Utils

  import Ecto.Query, warn: false

  @behaviour DataProtocol

  @impl DataProtocol
  def resources(_conn) do
    {:ok, setup_resources()}
  end

  @impl DataProtocol
  def list(conn) do
    resource = get_resource(conn)
    params = conn.query_params
    per_page = Map.get(params, "limit", "100") |> String.to_integer()
    page = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "search", "") |> String.trim()
    search_fields = Kaffy.ResourceAdmin.search_fields(resource)
    filtered_fields = get_filter_fields(params, resource)
    ordering = get_ordering(resource, params)

    current_offset = (page - 1) * per_page
    schema = resource[:schema]

    {all, paged} =
      build_query(
        schema,
        search_fields,
        filtered_fields,
        search,
        per_page,
        ordering,
        current_offset
      )

    {current_page, opts} =
      case Kaffy.ResourceAdmin.custom_index_query(conn, resource, paged) do
        {custom_query, opts} ->
          {Kaffy.Utils.repo().all(custom_query, opts), opts}

        custom_query ->
          {Kaffy.Utils.repo().all(custom_query), []}
      end

    do_cache = if search == "" and Enum.empty?(filtered_fields), do: true, else: false
    all_count = cached_total_count(schema, do_cache, all, opts)
    {all_count, current_page}
  end

  @impl DataProtocol
  def get_resource(conn) do
    %{"context" => context, "resource" => resource} = parse_url_path(conn)
    {context, resource} = convert_to_atoms(context, resource)
    {:ok, resources} = resources(conn)
    get_in(resources, [context, :resources, resource])
  end

  defp setup_resources do
    otp_app = env(:otp_app)
    {:ok, mods} = :application.get_key(otp_app, :modules)

    mods
    |> get_schemas()
    |> build_resources()
  end

  defp get_schemas(mods) do
    Enum.filter(mods, fn m ->
      functions = m.__info__(:functions)
      Keyword.has_key?(functions, :__schema__) && Map.has_key?(m.__struct__, :__meta__)
    end)
  end

  defp build_resources(schemas) do
    Enum.reduce(schemas, [], fn schema, resources ->
      schema_module =
        to_string(schema)
        |> String.split(".")

      context_module =
        schema_module
        |> Enum.reverse()
        |> tl()
        |> Enum.reverse()
        |> Enum.join(".")

      context_name =
        schema_module
        |> Enum.at(-2)
        |> Macro.underscore()
        |> String.to_atom()

      schema_name_string =
        schema_module
        |> Enum.at(-1)

      schema_name =
        schema_name_string
        |> Macro.underscore()
        |> String.to_atom()

      schema_admin = String.to_atom("#{context_module}.#{schema_name_string}Admin")

      schema_options =
        case function_exported?(schema_admin, :__info__, 1) do
          true -> [schema: schema, admin: schema_admin]
          false -> [schema: schema]
        end

      humanized_context = Utils.humanize_term(context_name)
      resources = Keyword.put_new(resources, context_name, name: humanized_context, resources: [])
      resources = put_in(resources, [context_name, :resources, schema_name], schema_options)
      existing_schemas = get_in(resources, [context_name, :resources]) |> Enum.sort()
      put_in(resources, [context_name, :resources], existing_schemas)
    end)
    |> Enum.sort()
  end

  def env(key, default \\ nil) do
    Application.get_env(:kaffy, key, default)
  end

  defp parse_url_path(conn) do
    params = conn.path_params

    %{
      "context" => Map.get(params, "context", ""),
      "resource" => Map.get(params, "resource", "")
    }
  end

  defp convert_to_atoms(context, resource) do
    {convert_to_atom(context), convert_to_atom(resource)}
  end

  defp convert_to_atom(string) do
    if is_binary(string), do: String.to_existing_atom(string), else: string
  end

  defp get_filter_fields(params, resource) do
    schema_fields =
      Kaffy.ResourceSchema.fields(resource[:schema]) |> Enum.map(fn {k, _} -> to_string(k) end)

    filtered_fields = Enum.filter(params, fn {k, v} -> k in schema_fields and v != "" end)

    Enum.map(filtered_fields, fn {name, value} ->
      %{name: name, value: value}
    end)
  end

  def fields(schema) do
    schema
    |> get_all_fields()
    |> reorder_fields(schema)
  end

  defp get_all_fields(schema) do
    schema.__changeset__()
    |> Enum.map(fn {k, _} -> {k, default_field_options(schema, k)} end)
  end

  def default_field_options(schema, field) do
    type = field_type(schema, field)
    label = Kaffy.ResourceForm.form_label_string(field)
    merge_field_options(%{label: label, type: type})
  end

  def merge_field_options(options) do
    default = %{
      create: :editable,
      update: :editable,
      label: nil,
      type: nil,
      choices: nil
    }

    Map.merge(default, options || %{})
  end

  defp reorder_fields(fields_list, schema) do
    [_id, first_field | _fields] = schema.__schema__(:fields)

    # this is a "nice" feature to re-order the default fields to put the specified fields at the top/bottom of the form
    fields_list
    |> reorder_field(first_field, :first)
    |> reorder_field(:email, :first)
    |> reorder_field(:name, :first)
    |> reorder_field(:title, :first)
    |> reorder_field(:id, :first)
    |> reorder_field(:inserted_at, :last)
    |> reorder_field(:updated_at, :last)

    # |> reorder_field(Kaffy.ResourceSchema.embeds(schema), :last)
  end

  defp reorder_field(fields_list, [], _), do: fields_list

  defp reorder_field(fields_list, [field | rest], position) do
    fields_list = reorder_field(fields_list, field, position)
    reorder_field(fields_list, rest, position)
  end

  defp reorder_field(fields_list, field_name, position) do
    if field_name in Keyword.keys(fields_list) do
      {field_options, fields_list} = Keyword.pop(fields_list, field_name)

      case position do
        :first -> [{field_name, field_options}] ++ fields_list
        :last -> fields_list ++ [{field_name, field_options}]
      end
    else
      fields_list
    end
  end

  def field_type(_schema, {_, type}), do: type
  def field_type(schema, field), do: schema.__changeset__() |> Map.get(field, :string)

  def get_ordering(resource, params) do
    default_ordering = Kaffy.ResourceAdmin.ordering(resource)
    default_order_field = Map.get(params, "_of", "nil") |> String.to_existing_atom()
    default_order_way = Map.get(params, "_ow", "nil") |> String.to_existing_atom()

    case is_nil(default_order_field) or is_nil(default_order_way) do
      true -> default_ordering
      false -> [{default_order_way, default_order_field}]
    end
  end

  defp build_query(
         schema,
         search_fields,
         filtered_fields,
         search,
         per_page,
         ordering,
         current_offset
       ) do
    query = from(s in schema)

    query =
      cond do
        is_nil(search_fields) || Enum.empty?(search_fields) || search == "" ->
          query

        true ->
          term =
            search
            |> String.replace("%", "\%")
            |> String.replace("_", "\_")

          term = "%#{term}%"

          Enum.reduce(search_fields, query, fn
            {association, fields}, q ->
              query = from(s in q, join: a in assoc(s, ^association))

              Enum.reduce(fields, query, fn f, current_query ->
                from([..., r] in current_query,
                  or_where: ilike(type(field(r, ^f), :string), ^term)
                )
              end)

            f, q ->
              from(s in q, or_where: ilike(type(field(s, ^f), :string), ^term))
          end)
      end

    query = build_filtered_fields_query(query, filtered_fields)

    limited_query =
      from(s in query, limit: ^per_page, offset: ^current_offset, order_by: ^ordering)

    {query, limited_query}
  end

  def cached_total_count(schema, do_cache, query, opts \\ [])

  def cached_total_count(schema, false, query, opts), do: total_count(schema, false, query, opts)

  def cached_total_count(schema, do_cache, query, opts) do
    Kaffy.Cache.Client.get_cache(schema, "count") || total_count(schema, do_cache, query, opts)
  end

  def total_count(schema, do_cache, query, opts \\ [])

  def total_count(schema, do_cache, query, opts) do
    result =
      from(s in query, select: fragment("count(*)"))
      |> Kaffy.Utils.repo().one(opts)

    if do_cache and result > 100_000 do
      Kaffy.Cache.Client.add_cache(schema, "count", result, 600)
    end

    result
  end

  defp build_filtered_fields_query(query, []), do: query

  defp build_filtered_fields_query(query, [filter | rest]) do
    query =
      case filter.value == "" do
        true ->
          query

        false ->
          field_name = String.to_existing_atom(filter.name)
          from(s in query, where: field(s, ^field_name) == ^filter.value)
      end

    build_filtered_fields_query(query, rest)
  end
end
