defmodule Kaffy.Pagination do
  @moduledoc false

  # number of pages to show on the showleft/right of the current page
  @pagination_delta 2

  def get_pages(0, 0), do: []

  def get_pages(current_page, total_page) do
    showleft = current_page - @pagination_delta
    showright = current_page + @pagination_delta + 1

    range =
      Enum.filter(1..total_page, fn x ->
        if x == 1 or x == total_page or (x >= showleft and x < showright), do: x
      end)

    range
    |> add_dots
  end

  defp add_dots(range) do
    {added_dots, _acc} =
      Enum.map_reduce(range, 0, fn x, last ->
        adding_page =
          if last > 0 do
            if x - last == 2 do
              last + 1
            else
              if x - last != 1, do: "..."
            end
          end

        current_page = if adding_page, do: [adding_page, x], else: [x]

        {current_page, x}
      end)

    added_dots
    |> List.flatten()
  end
end
