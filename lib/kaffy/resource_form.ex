defmodule Kaffy.ResourceForm do
  use Phoenix.HTML

  def form_label_string({field, options}), do: Map.get(options, :label, field)
  def form_label_string(field) when is_atom(field), do: field

  def form_label(form, field) do
    label_text = form_label_string(field)
    label(form, label_text)
  end

  def bare_form_field(resource, form, {field, options}) do
    options = options || %{}
    type = Map.get(options, :type, Kaffy.ResourceSchema.field_type(resource[:schema], field))
    permission = Map.get(options, :permission, :write)
    choices = Map.get(options, :choices)

    cond do
      !is_nil(choices) ->
        select(form, field, choices, class: "custom-select")

      permission == :read ->
        content_tag(
          :div,
          label(form, field, Kaffy.ResourceSchema.kaffy_field_value(resource[:schema], field))
        )

      true ->
        build_html_input(resource[:schema], form, field, type, [])
    end
  end

  def form_field(changeset, form, field, opts \\ [])

  def form_field(changeset, form, {field, options}, opts) do
    options = options || %{}

    type =
      Map.get(options, :type, Kaffy.ResourceSchema.field_type(changeset.data.__struct__, field))

    opts =
      if type == :textarea do
        rows = Map.get(options, :rows, 5)
        Keyword.put(opts, :rows, rows)
      else
        opts
      end

    permission =
      case is_nil(changeset.data.id) do
        true -> Map.get(options, :create, :editable)
        false -> Map.get(options, :update, :editable)
      end

    choices = Map.get(options, :choices)

    cond do
      !is_nil(choices) ->
        select(form, field, choices, class: "custom-select")

      true ->
        build_html_input(changeset.data, form, field, type, opts, permission == :readonly)
    end
  end

  def form_field(changeset, form, field, opts) do
    type = Kaffy.ResourceSchema.field_type(changeset.data.__struct__, field)
    build_html_input(changeset.data, form, field, type, opts)
  end

  defp build_html_input(schema, form, field, type, opts, readonly \\ false) do
    data = schema
    {conn, opts} = Keyword.pop(opts, :conn)
    opts = Keyword.put(opts, :readonly, readonly)
    schema = schema.__struct__

    case type do
      {:embed, _} ->
        embed = Kaffy.ResourceSchema.embed_struct(schema, field)
        embed_fields = Kaffy.ResourceSchema.fields(embed)
        embed_changeset = Ecto.Changeset.change(Map.get(data, field) || embed.__struct__)

        inputs_for(form, field, fn fp ->
          [
            {:safe, ~s(<div class="card ml-3" style="padding:15px;">)},
            Enum.reduce(embed_fields, [], fn f, all ->
              content_tag :div, class: "form-group" do
                [
                  [
                    form_label(fp, f),
                    form_field(embed_changeset, fp, f, class: "form-control")
                  ]
                  | all
                ]
              end
            end),
            {:safe, "</div>"}
          ]
        end)

      :id ->
        case Kaffy.ResourceSchema.primary_key(schema) == [field] do
          true -> text_input(form, field, opts)
          false -> text_or_assoc(conn, schema, form, field, opts)
        end

      :string ->
        text_input(form, field, opts)

      :richtext ->
        opts = Keyword.put(opts, :class, "kaffy-editor")
        textarea(form, field, opts)

      :textarea ->
        textarea(form, field, opts)

      :integer ->
        number_input(form, field, opts)

      :float ->
        text_input(form, field, opts)

      :decimal ->
        text_input(form, field, opts)

      t when t in [:boolean, :boolean_checkbox] ->
        checkbox_opts = Keyword.put(opts, :class, "custom-control-input")
        label_opts = Keyword.put(opts, :class, "custom-control-label")

        [
          {:safe, ~s(<div class="custom-control custom-checkbox">)},
          checkbox(form, field, checkbox_opts),
          label(form, field, label_opts),
          {:safe, "</div>"}
        ]

      :boolean_switch ->
        checkbox_opts = Keyword.put(opts, :class, "custom-control-input")
        label_opts = Keyword.put(opts, :class, "custom-control-label")

        [
          {:safe, ~s(<div class="custom-control custom-switch">)},
          checkbox(form, field, checkbox_opts),
          label(form, field, label_opts),
          {:safe, "</div>"}
        ]

      :map ->
        value = Map.get(data, field, "")

        value =
          cond do
            is_map(value) -> Kaffy.Utils.json().encode!(value, escape: :html_safe, pretty: true)
            true -> value
          end

        textarea(form, field, [value: value, rows: 4, placeholder: "JSON Content"] ++ opts)

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

  defp text_or_assoc(conn, schema, form, field, opts) do
    actual_assoc =
      Enum.filter(Kaffy.ResourceSchema.associations(schema), fn a ->
        Kaffy.ResourceSchema.association(schema, a).owner_key == field
      end)
      |> Enum.at(0)

    field_no_id =
      case actual_assoc do
        nil -> field
        _ -> Kaffy.ResourceSchema.association(schema, actual_assoc).field
      end

    case field_no_id in Kaffy.ResourceSchema.associations(schema) do
      true ->
        assoc = Kaffy.ResourceSchema.association_schema(schema, field_no_id)
        option_count = Kaffy.ResourceQuery.cached_total_count(assoc, true, assoc)

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

            fields = Kaffy.ResourceSchema.fields(assoc)

            string_fields = Enum.filter(fields, fn {_f, options} -> options.type == :string end)

            popular_strings =
              string_fields
              |> Enum.filter(fn {f, _} -> f in [:name, :title] end)
              |> Enum.at(0)

            string_field =
              case is_nil(popular_strings) do
                true -> Enum.at(string_fields, 0)
                false -> elem(popular_strings, 0)
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
end
