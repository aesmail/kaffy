defmodule Kaffy.InflectorTest do
  use ExUnit.Case, async: true
  alias Kaffy.Inflector

  test "known exception", do: assert_plural("Person", "People")
  test "known exception matching another rule", do: assert_plural("Chief", "Chiefs")

  test "ending with -s", do: assert_plural("Bus", "Buses")
  test "ending with -sh", do: assert_plural("Marsh", "Marshes")
  test "ending with -ch", do: assert_plural("Lunch", "Lunches")
  test "ending with -x", do: assert_plural("Tax", "Taxes")
  test "ending with -z", do: assert_plural("Buzz", "Buzzes")

  test "ending with -fe", do: assert_plural("Wife", "Wives")
  test "ending with -f", do: assert_plural("Calf", "Calves")

  test "ending with vowel + -y", do: assert_plural("Clay", "Clays")
  test "ending with consonant + -y", do: assert_plural("Company", "Companies")

  test "ending with -is", do: assert_plural("Analysis", "Analyses")

  test "regular word", do: assert_plural("Node", "Nodes")

  defp assert_plural(singular, plural) do
    assert Inflector.pluralize(singular) == plural
  end
 end
