defmodule Kaffy.PaginationTest do
  alias Kaffy.Pagination
  use ExUnit.Case

  # testing for get_pages(current_page, total_page)

  test "test on empty pages" do
    pages = Pagination.get_pages(1, 0)
    assert pages == []
  end

  test "test on low get_pages" do
    assert Pagination.get_pages(1, 1) == [1]
    assert Pagination.get_pages(1, 2) == [1, 2]
    assert Pagination.get_pages(1, 3) == [1, 2, 3]
    assert Pagination.get_pages(1, 4) == [1, 2, 3, 4]
    assert Pagination.get_pages(1, 5) == [1, 2, 3, 4, 5]
    assert Pagination.get_pages(1, 6) == [1, 2, 3, "...", 6]
  end

  test "test on pagination 10" do
    pages = Pagination.get_pages(5, 10)
    assert pages == [1, 2, 3, 4, 5, 6, 7, "...", 10]
  end

  test "test on pagination 20" do
    test_list_20 = [
      {1, [1, 2, 3, "...", 20]},
      {2, [1, 2, 3, 4, "...", 20]},
      {3, [1, 2, 3, 4, 5, "...", 20]},
      {4, [1, 2, 3, 4, 5, 6, "...", 20]},
      {5, [1, 2, 3, 4, 5, 6, 7, "...", 20]},
      {6, [1, "...", 4, 5, 6, 7, 8, "...", 20]},
      {7, [1, "...", 5, 6, 7, 8, 9, "...", 20]},
      {8, [1, "...", 6, 7, 8, 9, 10, "...", 20]},
      {9, [1, "...", 7, 8, 9, 10, 11, "...", 20]},
      {10, [1, "...", 8, 9, 10, 11, 12, "...", 20]},
      {11, [1, "...", 9, 10, 11, 12, 13, "...", 20]},
      {12, [1, "...", 10, 11, 12, 13, 14, "...", 20]},
      {13, [1, "...", 11, 12, 13, 14, 15, "...", 20]},
      {14, [1, "...", 12, 13, 14, 15, 16, "...", 20]},
      {15, [1, "...", 13, 14, 15, 16, 17, "...", 20]},
      {16, [1, "...", 14, 15, 16, 17, 18, 19, 20]},
      {17, [1, "...", 15, 16, 17, 18, 19, 20]},
      {18, [1, "...", 16, 17, 18, 19, 20]},
      {19, [1, "...", 17, 18, 19, 20]},
      {20, [1, "...", 18, 19, 20]}
    ]

    Enum.map(test_list_20, fn {x, y} ->
      assert Pagination.get_pages(x, 20) == y
    end)
  end
end
