defmodule Kaffy.ResourceQuery do
  @moduledoc false

  import Ecto.Query

  def list_resource(resource, params \\ %{}) do
    per_page = Map.get(params, "length", "10") |> String.to_integer()
    # page = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "search", %{}) |> Map.get("value", "") |> String.trim()
    search_fields = Kaffy.ResourceAdmin.search_fields(resource)
    filtered_fields = get_filter_fields(params)
    default_ordering = Kaffy.ResourceAdmin.ordering(resource)
    ordering = Map.get(params, "ordering", default_ordering)
    current_offset = Map.get(params, "start", "0") |> String.to_integer()
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

    current_page = Kaffy.Utils.repo().all(paged)
    all_count = from(r in all, select: count(r.id)) |> Kaffy.Utils.repo().one()
    {all_count, current_page}
  end

  def fetch_resource(resource, id) do
    schema = resource[:schema]
    Kaffy.Utils.repo().get(schema, id)
  end

  def fetch_list(_, [""]), do: []

  def fetch_list(resource, ids) do
    schema = resource[:schema]

    from(s in schema, where: s.id in ^ids)
    |> Kaffy.Utils.repo().all()
  end

  def total_count(resource) do
    schema = resource[:schema]

    from(s in schema, select: count(s.id))
    |> Kaffy.Utils.repo().one()
  end

  def total_pages(resource, params \\ %{}) do
    per_page = Map.get(params, "limit", "100") |> String.to_integer()
    total = total_count(resource)
    :math.ceil(total / per_page)
  end

  defp get_filter_fields(params) do
    columns = Map.get(params, "columns", %{})

    Enum.map(columns, fn {_key, column} ->
      field_name = get_in(column, ["name"])
      field_value = get_in(column, ["search", "value"])
      %{name: field_name, value: field_value}
    end)
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
        is_nil(search_fields) or search == "" ->
          query

        true ->
          term = String.replace(search, ["%", "_"], "")
          term = "%#{term}%"

          Enum.reduce(search_fields, query, fn
            {association, fields}, q ->
              query = from(s in q, join: a in assoc(s, ^association))

              Enum.reduce(fields, query, fn f, current_query ->
                from([..., r] in current_query, or_where: ilike(field(r, ^f), ^term))
              end)

            f, q ->
              from(s in q, or_where: ilike(field(s, ^f), ^term))
          end)
      end

    query = build_filtered_fields_query(query, filtered_fields)

    limited_query =
      from(s in query, limit: ^per_page, offset: ^current_offset, order_by: ^ordering)

    {query, limited_query}
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
