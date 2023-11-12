defmodule Kaffy.Pagination do
  @moduledoc false

  # number of pages to show on the showleft/right of the current page
  @pagination_delta 2

  def get_pages(1, 0), do: []

  def get_pages(current_page, total_page) do
    showleft = current_page - @pagination_delta
    showright = current_page + @pagination_delta + 1

    1..total_page
    |> Enum.filter(fn x -> x == 1 || x == total_page || (x >= showleft && x < showright) end)
    |> add_dots()
  end

  defp add_dots(range) do
    {added_dots, _acc} =
      Enum.map_reduce(range, 0, fn x, last ->
        current_page = if adding_page = add_dots_check(x, last), do: [adding_page, x], else: [x]
        {current_page, x}
      end)

    added_dots
    |> List.flatten()
  end

  defp add_dots_check(x, last) when last > 0 and x - last == 2, do: last + 1
  defp add_dots_check(x, last) when last > 0 and x - last != 1, do: "..."
  defp add_dots_check(_, _), do: nil
end
