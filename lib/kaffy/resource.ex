defmodule Kaffy.Resource do
  @moduledoc false

  use Phoenix.HTML

  def excluded_fields(schema) do
    {field, _, _} = schema.__schema__(:autogenerate_id)
    [field]
  end

  def primary_keys(schema) do
    schema.__schema__(:primary_key)
  end

  def kaffy_field_name(schema, {field, options}) do
    default_name = kaffy_field_name(schema, field)
    name = Map.get(options || %{}, :name)

    cond do
      is_binary(name) -> name
      is_function(name) -> name.(schema)
      true -> default_name
    end
  end

  def kaffy_field_name(_schema, field) when is_atom(field) do
    to_string(field) |> String.capitalize()
  end

  def kaffy_field_value(schema, {field, options}) do
    default_value = kaffy_field_value(schema, field)
    value = Map.get(options || %{}, :value)

    cond do
      is_struct(value) ->
        if value.__struct__ in [NaiveDateTime, DateTime, Date, Time] do
          value
        else
          Map.from_struct(value)
          |> Map.drop([:__meta__])
          |> Kaffy.Utils.json().encode!(escape: :html_safe, pretty: true)
        end

      is_binary(value) ->
        value

      is_function(value) ->
        value.(schema)

      is_map(value) ->
        Kaffy.Utils.json().encode!(value, escape: :html_safe, pretty: true)

      true ->
        default_value
    end
  end

  def kaffy_field_value(schema, field) when is_atom(field) do
    value = Map.get(schema, field, "")

    cond do
      is_struct(value) ->
        if value.__struct__ in [NaiveDateTime, DateTime, Date, Time] do
          value
        else
          Map.from_struct(value)
          |> Map.drop([:__meta__])
          |> Kaffy.Utils.json().encode!(escape: :html_safe, pretty: true)
        end

      is_map(value) ->
        Kaffy.Utils.json().encode!(value, escape: :html_safe, pretty: true)

      true ->
        value
    end
  end

  def fields(schema) do
    to_be_removed = fields_to_be_removed(schema)
    all_fields = all_fields(schema) -- to_be_removed
    reorder_fields(all_fields, schema)
  end

  defp fields_to_be_removed(schema) do
    # if schema defines belongs_to assocations, remove the respective *_id fields.
    schema.__changeset__()
    |> Enum.reduce([], fn {field, type}, all ->
      case type do
        {:assoc, %Ecto.Association.BelongsTo{}} ->
          [field | all]

        {:assoc, %Ecto.Association.Has{cardinality: :many}} ->
          [field | all]

        {:assoc, %Ecto.Association.Has{cardinality: :one}} ->
          [field | all]

        _ ->
          all
      end
    end)
  end

  defp all_fields(schema) do
    schema.__changeset__()
    |> Enum.map(fn {k, _} -> k end)
  end

  defp reorder_fields(fields_list, schema) do
    fields_list
    |> reorder_field(:name, :first)
    |> reorder_field(:title, :first)
    |> reorder_field(:id, :first)
    |> reorder_field(embeds(schema), :last)
    |> reorder_field([:inserted_at, :updated_at], :last)
  end

  defp reorder_field(fields_list, [], _), do: fields_list

  defp reorder_field(fields_list, [field | rest], position) do
    fields_list = reorder_field(fields_list, field, position)
    reorder_field(fields_list, rest, position)
  end

  defp reorder_field(fields_list, field, position) do
    if field in fields_list do
      fields_list = fields_list -- [field]

      case position do
        :first -> [field] ++ fields_list
        :last -> fields_list ++ [field]
      end
    else
      fields_list
    end
  end

  def associations(schema) do
    schema.__schema__(:associations)
  end

  def association(schema, name) do
    schema.__schema__(:association, name)
  end

  def association_schema(schema, assoc) do
    association(schema, assoc).queryable
  end

  def embeds(schema) do
    schema.__schema__(:embeds)
  end

  def embed(schema, name) do
    schema.__schema__(:embed, name)
  end

  def embed_struct(schema, name) do
    embed(schema, name).related
  end

  def form_label(form, {field, options}) do
    options = options || %{}
    label_text = Map.get(options, :label, field)
    form_label(form, label_text)
  end

  def form_label(form, field) do
    label(form, field)
  end

  def bare_form_field(resource, form, {field, options}) do
    options = options || %{}
    type = Map.get(options, :type, field_type(resource[:schema], field))
    permission = Map.get(options, :permission, :write)
    choices = Map.get(options, :choices)

    cond do
      !is_nil(choices) ->
        select(form, field, choices, class: "custom-select")

      permission == :read ->
        content_tag(:div, label(form, field, kaffy_field_value(resource[:schema], field)))

      true ->
        build_html_input(resource[:schema], form, field, type, [])
    end
  end

  def form_field(changeset, form, field, opts \\ [])

  def form_field(changeset, form, {field, options}, opts) do
    options = options || %{}
    type = Map.get(options, :type, field_type(changeset.data.__struct__, field))

    opts =
      if type == :textarea do
        rows = Map.get(options, :rows, 5)
        Keyword.put(opts, :rows, rows)
      else
        opts
      end

    permission = Map.get(options, :permission, :write)
    choices = Map.get(options, :choices)

    cond do
      !is_nil(choices) ->
        select(form, field, choices, class: "custom-select")

      permission == :read ->
        content_tag(:div, label(form, field, kaffy_field_value(changeset.data, field)))

      true ->
        build_html_input(changeset.data, form, field, type, opts)
    end
  end

  def form_field(changeset, form, field, opts) do
    type = field_type(changeset.data.__struct__, field)
    build_html_input(changeset.data, form, field, type, opts)
  end

  defp build_html_input(schema, form, field, type, opts) do
    data = schema
    {conn, opts} = Keyword.pop(opts, :conn)
    schema = schema.__struct__

    case type do
      {:embed, _} ->
        embed = embed_struct(schema, field)
        embed_fields = fields(embed)
        embed_changeset = Ecto.Changeset.change(Map.get(data, field) || embed.__struct__)

        inputs_for(form, field, fn fp ->
          [
            {:safe, ~s(<div class="card ml-3" style="padding:15px;">)},
            Enum.reduce(embed_fields, [], fn f, all ->
              content_tag :div, class: "form-group" do
                [
                  [
                    Kaffy.Resource.form_label(fp, f),
                    Kaffy.Resource.form_field(embed_changeset, fp, f, class: "form-control")
                  ]
                  | all
                ]
              end
            end),
            {:safe, "</div>"}
          ]
        end)

      :id ->
        text_or_assoc(conn, schema, form, field, opts)

      :string ->
        text_input(form, field, opts)

      :textarea ->
        textarea(form, field, opts)

      :integer ->
        number_input(form, field, opts)

      :float ->
        text_input(form, field, opts)

      :decimal ->
        text_input(form, field, opts)

      :boolean ->
        checkbox(form, field)

      :map ->
        value = Map.get(data, field, "")

        value =
          cond do
            is_map(value) -> Kaffy.Utils.json().encode!(value, escape: :html_safe, pretty: true)
            true -> value
          end

        textarea(form, field, [value: value, rows: 4] ++ opts)

      :file ->
        file_input(form, field, opts)

      :date ->
        date_select(form, field, opts)

      :time ->
        time_select(form, field, opts)

      :select ->
        select(form, field, opts)

      :naive_datetime ->
        datetime_select(form, field, opts)

      :naive_datetime_usec ->
        datetime_select(form, field, opts)

      :utc_datetime ->
        datetime_select(form, field, opts)

      :utc_datetime_usec ->
        datetime_select(form, field, opts)

      _ ->
        text_input(form, field, opts)
    end
  end

  def search_fields(resource) do
    schema = resource[:schema]
    Enum.filter(fields(schema), fn f -> field_type(schema, f) == :string end)
  end

  def filter_fields(_), do: nil

  def field_type(_schema, {_, type}), do: type
  def field_type(schema, field), do: schema.__schema__(:type, field)

  defp text_or_assoc(conn, schema, form, field, opts) do
    actual_assoc =
      Enum.filter(associations(schema), fn a ->
        association(schema, a).owner_key == field
      end)
      |> Enum.at(0)

    field_no_id =
      case actual_assoc do
        nil -> field
        _ -> association(schema, actual_assoc).field
      end

    case field_no_id in associations(schema) do
      true ->
        assoc = association_schema(schema, field_no_id)
        option_count = Kaffy.ResourceQuery.total_count(schema: assoc)

        case option_count > 20 do
          true ->
            target_context = Kaffy.Utils.get_context_for_schema(assoc)
            target_resource = Kaffy.Utils.get_schema_key(target_context, assoc)

            content_tag :div, class: "input-group col-md-2" do
              [
                number_input(form, field,
                  class: "form-control",
                  id: field,
                  aria_describedby: field
                ),
                content_tag :div, class: "input-group-append" do
                  content_tag :span, class: "input-group-text", id: field do
                    link(content_tag(:i, "", class: "fas fa-search"),
                      to:
                        Kaffy.Utils.router().kaffy_resource_path(
                          conn,
                          :index,
                          target_context,
                          target_resource,
                          c: conn.params["context"],
                          r: conn.params["resource"],
                          pick: field
                        ),
                      id: "pick-raw-resource"
                    )
                  end
                end
              ]
            end

          false ->
            options = Kaffy.Utils.repo().all(assoc)

            string_fields =
              Enum.filter(fields(assoc), fn f -> field_type(assoc, f) == :string end)

            popular_strings =
              Enum.filter(string_fields, fn f -> f in [:name, :title] end) |> Enum.at(0)

            string_field =
              case is_nil(popular_strings) do
                true -> Enum.at(string_fields, 0)
                false -> popular_strings
              end

            select(
              form,
              field,
              Enum.map(options, fn o -> {Map.get(o, string_field, "ERROR"), o.id} end),
              class: "custom-select"
            )
        end

      false ->
        number_input(form, field, opts)
    end
  end

  def display_errors(form) do
    errors =
      case length(form.errors) do
        0 ->
          []

        _x ->
          keys = Keyword.keys(form.errors) |> Enum.uniq()

          for field <- keys,
              do:
                Enum.map(Keyword.get_values(form.errors, field), fn {msg, opts} ->
                  msg =
                    if count = opts[:count] do
                      String.replace(msg, "%{count}", to_string(count))
                    else
                      msg
                    end

                  content_tag :div, class: "alert alert-danger" do
                    content_tag(:span, to_string(field) <> " " <> msg)
                  end
                end)
      end

    Enum.reduce(errors, [], fn error, combined ->
      Enum.reduce(error, combined, fn e, all -> [e | all] end)
    end)
  end

  def get_map_fields(schema) do
    all_fields(schema)
    |> Enum.filter(fn f -> field_type(schema, f) == :map end)
  end

  def decode_map_fields(resource, schema, params) do
    map_fields = get_map_fields(schema) |> Enum.map(fn f -> to_string(f) end)

    attrs =
      Map.get(params, resource, %{})
      |> Enum.map(fn {k, v} ->
        case k in map_fields && String.length(v) > 0 do
          true -> {k, Kaffy.Utils.json().decode!(v)}
          false -> {k, v}
        end
      end)
      |> Map.new()

    attrs =
      Enum.reduce(embeds(schema), attrs, fn e, params ->
        embed_schema = embed_struct(schema, e)

        embed_map_fields =
          fields(embed_schema) |> Enum.filter(fn f -> field_type(embed_schema, f) == :map end)

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
