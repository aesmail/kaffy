defmodule KaffyTest do
  use ExUnit.Case
  doctest Kaffy

  test "greets the world" do
    assert Kaffy.hello() == :world
  end
end
