defmodule Kaffy.ResourceQuery do
  import Ecto.Query

  def list_resource(resource, params \\ %{}) do
    per_page = Map.get(params, "limit", "100") |> String.to_integer()
    page = Map.get(params, "page", "1") |> String.to_integer()
    default_ordering = Kaffy.ResourceAdmin.ordering(resource)
    ordering = Map.get(params, "ordering", default_ordering)
    current_offset = (page - 1) * per_page
    schema = resource[:schema]

    from(s in schema, limit: ^per_page, offset: ^current_offset, order_by: ^ordering)
    |> Kaffy.Utils.repo().all()
  end

  def fetch_resource(resource, id) do
    schema = resource[:schema]
    Kaffy.Utils.repo().get(schema, id)
  end

  def total_pages(resource, params \\ %{}) do
    schema = resource[:schema]
    per_page = Map.get(params, "limit", "100") |> String.to_integer()

    total =
      from(s in schema, select: count(s.id))
      |> Kaffy.Utils.repo().one()

    :math.ceil(total / per_page)
  end
end
