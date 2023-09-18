defmodule Kaffy.ResourceParams do
  alias Kaffy.ResourceSchema

  def decode_map_fields(resource, schema, params) do
    map_fields = ResourceSchema.get_map_fields(schema) |> Enum.map(fn {f, _} -> to_string(f) end)

    attrs =
      Map.get(params, resource, %{})
      |> Enum.map(fn {k, v} ->
        case is_list(v) do
          true ->
            {k, v}

          false ->
            case k in map_fields && String.length(v) > 0 do
              true -> {k, Kaffy.Utils.json().decode!(v)}
              false -> {k, v}
            end
        end
      end)
      |> Map.new()

    attrs =
      Enum.reduce(ResourceSchema.embeds(schema), attrs, fn e, params ->
        embed_schema = ResourceSchema.embed_struct(schema, e)

        embed_map_fields =
          ResourceSchema.fields(embed_schema)
          |> Enum.filter(fn f -> ResourceSchema.field_type(embed_schema, f) == :map end)

        Enum.reduce(embed_map_fields, params, fn f, p ->
          json_string = get_in(attrs, [to_string(e), to_string(f)])

          if json_string && String.length(json_string) > 0 do
            json_object = Kaffy.Utils.json().decode!(json_string)
            put_in(p, [to_string(e), to_string(f)], json_object)
          else
            p
          end
        end)
      end)

    Map.put(params, resource, attrs)
  end
end
