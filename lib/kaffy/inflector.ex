defmodule Kaffy.Inflector do
  @moduledoc """
  Module holding functions related to inflection of words. It does not attempt to
  be perfect, rather aiming at being "good enough".
  """

  @exceptions %{
    "Person" => "People",
    "Roof" => "Roofs",
    "Belief" => "Beliefs",
    "Chef" => "Chefs",
    "Chief" => "Chiefs",
    "Index" => "Indices",
    "Sheep" => "Sheep",
    "Series" => "Series",
    "Species" => "Species",
    "Deer" => "Deer",
    "Child" => "Children",
    "Man" => "Men",
    "Woman" => "Women",
    "Goose" => "Geese",
    "Tooth" => "Teeth",
    "Foot" => "Feet",
    "Mouse" => "Mice"
  }

  @vowels ["a", "e", "i", "o", "u", "y"]

  @doc """
  Attempts to create a correct plural version by following rules outlined at:
  https://www.grammarly.com/blog/plural-nouns/

  Some of these rules are conscously ommited as being rare and hard to implement.
  """
  def pluralize(noun) when is_binary(noun) do
    case Map.has_key?(@exceptions, noun) do
      true -> @exceptions[noun]
      false -> try_to_pluralize(noun)
    end
  end

  defp try_to_pluralize(noun) do
    reversed_noun = String.reverse(noun)

    case reversed_noun do
      <<"si", rest::binary>> ->
        String.reverse(rest) <> "es"

      <<"s", _rest::binary>> ->
        noun <> "es"

      <<"hs", _rest::binary>> ->
        noun <> "es"

      <<"hc", _rest::binary>> ->
        noun <> "es"

      <<"x", _rest::binary>> ->
        noun <> "es"

      <<"z", _rest::binary>> ->
        noun <> "es"

      <<"ef", rest::binary>> ->
        String.reverse(rest) <> "ves"

      <<"f", rest::binary>> ->
        String.reverse(rest) <> "ves"

      <<"y", preceding::binary-size(1), rest::binary>> ->
        case preceding in @vowels do
          true -> noun <> "s"
          false -> String.reverse(rest) <> preceding <> "ies"
        end

      _ ->
        noun <> "s"
    end
  end
end
