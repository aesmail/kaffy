defmodule Kaffy.ResourceForm do
  use PhoenixHTMLHelpers

  def form_label_string({field, options}), do: Map.get(options, :label, field)
  def form_label_string(field) when is_atom(field), do: field

  def form_label(form, field) do
    label_text = form_label_string(field)
    label(form, label_text)
  end

  def form_help_text({_field, options}), do: Map.get(options, :help_text, nil)
  def form_help_text(field) when is_atom(field), do: nil

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
        build_html_input(resource[:schema], form, {field, options}, type, [])
    end
  end

  def form_field(changeset, form, {field, options}, opts \\ []) do
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

    # Check if any primary key fields are nil
    is_create_event =
      changeset.data.__struct__
      |> Kaffy.ResourceSchema.primary_keys()
      |> Enum.map(&Map.get(changeset.data, &1))
      |> Enum.any?(&is_nil/1)

    permission =
      case is_create_event do
        true -> Map.get(options, :create, :editable)
        false -> Map.get(options, :update, :editable)
      end

    choices = Map.get(options, :choices)

    cond do
      !is_nil(choices) ->
        select(form, field, choices, class: "custom-select", disabled: permission == :readonly)

      true ->
        build_html_input(
          changeset.data,
          form,
          {field, options},
          type,
          opts,
          permission == :readonly
        )
    end
  end

  # def form_field(changeset, form, {field, options}, opts) do
  #   type = Kaffy.ResourceSchema.field_type(changeset.data.__struct__, field)
  #   build_html_input(changeset.data, form, {field, options}, type, opts)
  # end

  defp build_html_input(schema, form, {field, options}, type, opts, readonly \\ false) do
    data = schema
    {conn, opts} = Keyword.pop(opts, :conn)
    opts = Keyword.put(opts, :readonly, readonly)
    schema = schema.__struct__

    case type do
      {:embed, %{cardinality: :one}} ->
        embed = Kaffy.ResourceSchema.embed_struct(schema, field)
        embed_fields = Kaffy.ResourceSchema.fields(embed)
        embed_changeset = Ecto.Changeset.change(Map.get(data, field) || embed.__struct__)

        inputs_for(form, field, fn fp ->
          [
            {:safe, ~s(<div class="card ml-3" style="padding:15px;">)},
            Enum.reduce(embed_fields, [], fn {f, embed_options}, all ->
              content_tag :div, class: "form-group" do
                [
                  [
                    form_label(fp, f),
                    form_field(embed_changeset, fp, {f, embed_options}, class: "form-control")
                  ]
                  | all
                ]
              end
            end),
            {:safe, "</div>"}
          ]
        end)

      {:embed, _} ->
        value =
          data
          |> Map.get(field, "")
          |> Kaffy.Utils.json().encode!(escape: :html_safe, pretty: true)

        textarea(form, field, [value: value, rows: 4, placeholder: "JSON Content"] ++ opts)

      :id ->
        case field in Kaffy.ResourceSchema.primary_keys(schema) do
          true -> text_input(form, field, opts)
          false -> text_or_assoc(conn, schema, form, field, opts)
        end

      :binary_id ->
        case field in Kaffy.ResourceSchema.primary_keys(schema) do
          true -> text_input(form, field, opts)
          false -> text_or_assoc(conn, schema, form, field, opts)
        end

      :string ->
        text_input(form, field, opts)

      :richtext ->
        opts = add_class(opts, "kaffy-editor")
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
        checkbox_opts = add_class(opts, "custom-control-input")
        label_opts = add_class(opts, "custom-control-label")

        [
          {:safe, ~s(<div class="custom-control custom-checkbox">)},
          checkbox(form, field, checkbox_opts),
          label(form, field, form_label_string({field, options}), label_opts),
          {:safe, "</div>"}
        ]

      :boolean_switch ->
        checkbox_opts = add_class(opts, "custom-control-input")
        label_opts = add_class(opts, "custom-control-label")

        [
          {:safe, ~s(<div class="custom-control custom-switch">)},
          checkbox(form, field, checkbox_opts),
          label(form, field, form_label_string({field, options}), label_opts),
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

      {:parameterized, Ecto.Enum, %{values: values}} ->
        values = Enum.map(values, &to_string/1)
        value = Map.get(data, field, nil)

        # NOTE enum_options preserves the order of enum defined in the schema
        enum_options =
          Enum.map(values, fn v ->
            capitalized = String.capitalize(v)
            {capitalized, v}
          end)

        select(form, field, enum_options, [class: "custom-select", value: value] ++ opts)

      {:parameterized, Ecto.Enum, %{mappings: mappings, on_cast: on_cast}} ->
        value = Map.get(data, field, nil)

        # NOTE enum_options preserves the order of enum defined in the schema
        enum_options =
          Enum.map(mappings, fn {k, _} ->
            k = to_string(k)
            v = Map.get(on_cast, k)
            k = String.capitalize(k)
            {k, v}
          end)

        select(form, field, enum_options, [class: "custom-select", value: value] ++ opts)

      {:array, {:parameterized, Ecto.Enum, %{values: values}}} ->
        values = Enum.map(values, &to_string/1)
        value = Map.get(data, field, nil)

        # NOTE enum_options preserves the order of enum defined in the schema
        enum_options =
          Enum.map(values, fn v ->
            capitalized = String.capitalize(v)
            {capitalized, v}
          end)

        multiple_select(form, field, enum_options, [value: value] ++ opts)

      {:array, {:parameterized, Ecto.Enum, %{mappings: mappings, on_cast: on_cast}}} ->
        value = Map.get(data, field, nil)

        # NOTE enum_options preserves the order of enum defined in the schema
        enum_options =
          Enum.map(mappings, fn {k, _} ->
            k = to_string(k)
            v = Map.get(on_cast, k)
            k = String.capitalize(k)
            {k, v}
          end)

        multiple_select(form, field, enum_options, [value: value] ++ opts)

      {:array, _} ->
        case !is_nil(options[:values_fn]) && is_function(options[:values_fn], 2) do
          true ->
            values = options[:values_fn].(data, conn)
            value = Map.get(data, field, nil)
            multiple_select(form, field, values, [value: value] ++ opts)

          false ->
            value =
              data
              |> Map.get(field, "")
              |> Kaffy.Utils.json().encode!(escape: :html_safe, pretty: true)

            textarea(form, field, [value: value, rows: 4, placeholder: "JSON Content"] ++ opts)
        end

      :file ->
        file_input(form, field, opts)

      :select ->
        select(form, field, [class: "custom-select"] ++ opts)

      :color ->
        color_input(form, field, opts)

      :date ->
        flatpickr_date(form, field, opts)

      :time ->
        flatpickr_time(form, field, opts)

      :naive_datetime ->
        flatpickr_datetime(form, field, opts)

      :naive_datetime_usec ->
        flatpickr_datetime_usec(form, field, opts)

      :utc_datetime ->
        flatpickr_datetime(form, field, opts)

      :utc_datetime_usec ->
        flatpickr_datetime_usec(form, field, opts)

      Geo.PostGIS.Geometry ->
        value =
          data
          |> Map.get(field, "")
          |> Kaffy.Utils.json().encode!(escape: :html_safe, pretty: true)

        textarea(form, field, [value: value, rows: 4, placeholder: "JSON Content"] ++ opts)

      _ ->
        text_input(form, field, opts)
    end
  end

  defp flatpickr_time(form, field, opts) do
    flatpickr_generic(form, field, opts, "Select Date...", "flatpickr-wrap-time", "🕒")
  end

  defp flatpickr_date(form, field, opts) do
    flatpickr_generic(form, field, opts, "Select Date...", "flatpickr-wrap-date", "🗓️")
  end

  defp flatpickr_datetime(form, field, opts) do
    flatpickr_generic(form, field, opts, "Select Datetime...", "flatpickr-wrap-datetime")
  end

  defp flatpickr_datetime_usec(form, field, opts) do
    flatpickr_generic(form, field, opts, "Select Datetime...", "flatpickr-wrap-datetime-usec")
  end

  defp flatpickr_generic(form, field, opts, placeholder, fp_class, icon \\ "📅") do
    opts = add_class(opts, "flatpickr-input")
    opts = add_class(opts, "form-control")
    opts = Keyword.put(opts, :id, "inlineFormInputGroup")
    opts = Keyword.put(opts, :placeholder, placeholder)
    opts = Keyword.put(opts, :"data-input", "")
    editable = not Keyword.get(opts, :readonly, false)

    case editable do
      true ->
        [
          {:safe, ~s(
              <div class="input-group mb-2 flatpickr #{fp_class}">
                <div class="input-group-prepend">
                  <div class="input-group-text" data-clear>❌</div>
                </div>
                <div class="input-group-prepend">
                  <div class="input-group-text" data-toggle>#{icon}</div>
                </div>
            )},
          text_input(form, field, opts),
          {:safe, "</div>"}
        ]

      false ->
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

        case option_count > 100 do
          true ->
            target_context = Kaffy.Utils.get_context_for_schema(conn, assoc)
            target_resource = Kaffy.Utils.get_schema_key(conn, target_context, assoc)

            content_tag :div, class: "input-group" do
              [
                number_input(form, field,
                  class: "form-control",
                  id: field,
                  disabled: opts[:readonly],
                  aria_describedby: field
                ),
                if opts[:readonly] do
                  ""
                else
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
                end
              ]
            end

          false ->
            options = Kaffy.Utils.repo().all(assoc)

            fields = Kaffy.ResourceSchema.fields(assoc)

            string_fields =
              Enum.filter(fields, fn {_f, options} ->
                options.type == :string or
                  (Kaffy.Utils.is_module(options.type) and
                     Kernel.function_exported?(options.type, :type, 0) and
                     options.type.type == :string)
              end)

            popular_strings =
              string_fields
              |> Enum.filter(fn {f, _} -> f in [:name, :title] end)
              |> Enum.at(0)

            string_field =
              case is_nil(popular_strings) do
                true -> (Enum.at(string_fields, 0) || {:id}) |> elem(0)
                false -> elem(popular_strings, 0)
              end

            select(
              form,
              field,
              [{nil, nil}] ++
                Enum.map(options, fn o ->
                  {Map.get(o, string_field, "Resource ##{o.id}"), o.id}
                end),
              class: "custom-select",
              disabled: opts[:readonly]
            )
        end

      false ->
        number_input(form, field, opts)
    end
  end

  def get_field_error(changeset, field) do
    changeset
    |> build_error_messages()
    |> Map.get(field)
    |> case do
      nil ->
        {nil, ""}

      # # In case of field is a embedded schema
      %{} ->
        {nil, ""}

      messages ->
        error_msg =
          Kaffy.ResourceAdmin.humanize_term(field) <> " " <> Enum.join(messages, ", ") <> "!"

        {error_msg, "is-invalid"}
    end
  end

  defp build_error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", build_changeset_value(value))
      end)
    end)
  end

  defp build_changeset_value(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> Enum.join(", ")

  defp build_changeset_value(value) when is_list(value),
    do: value |> Enum.join(", ")

  defp build_changeset_value(value), do: to_string(value)

  def kaffy_input(conn, changeset, form, field, options) do
    ft = Kaffy.ResourceSchema.field_type(changeset.data.__struct__, field)

    case Kaffy.Utils.is_module(ft) && Keyword.has_key?(ft.__info__(:functions), :render_form) do
      true ->
        ft.render_form(conn, changeset, form, field, options)

      false ->
        {error_msg, error_class} = get_field_error(changeset, field)
        help_text = form_help_text({field, options})

        content_tag :div, class: "form-group #{error_class}" do
          label_tag = if ft != :boolean, do: form_label(form, {field, options}), else: ""

          field_tag =
            form_field(changeset, form, {field, options},
              class: "form-control #{error_class}",
              conn: conn
            )

          field_feeback = [
            content_tag :div, class: "invalid-feedback" do
              error_msg
            end,
            content_tag :p, class: "help_text" do
              help_text
            end
          ]

          [label_tag, field_tag, field_feeback]
        end
    end
  end

  defp add_class(opts, class) do
    Keyword.update(opts, :class, class, &"#{&1} #{class}")
  end
end
