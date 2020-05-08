defmodule Kaffy.ResourceQuery do
  import Ecto.Query

  def list_resource(resource, params \\ %{}) do
    per_page = Map.get(params, "length", "10") |> String.to_integer()
    # page = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "search", %{}) |> Map.get("value", "") |> String.trim()
    search_fields = Kaffy.ResourceAdmin.search_fields(resource)
    default_ordering = Kaffy.ResourceAdmin.ordering(resource)
    ordering = Map.get(params, "ordering", default_ordering)
    current_offset = Map.get(params, "start", "0") |> String.to_integer()
    schema = resource[:schema]

    {all, paged} = build_query(schema, search_fields, search, per_page, ordering, current_offset)
    current_page = Kaffy.Utils.repo().all(paged)
    all_count = from(r in all, select: count(r.id)) |> Kaffy.Utils.repo().one()
    {all_count, current_page}
  end

  def fetch_resource(resource, id) do
    schema = resource[:schema]
    Kaffy.Utils.repo().get(schema, id)
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

  defp build_query(schema, search_fields, search, per_page, ordering, current_offset) do
    query =
      cond do
        is_nil(search_fields) or search == "" ->
          schema

        true ->
          term = String.replace(search, ["%", "_"], "")
          term = "%#{term}%"

          Enum.reduce(search_fields, schema, fn f, q ->
            from(s in q, or_where: ilike(field(s, ^f), ^term))
          end)
      end

    limited_query =
      from(s in query, limit: ^per_page, offset: ^current_offset, order_by: ^ordering)

    {query, limited_query}
  end
end
