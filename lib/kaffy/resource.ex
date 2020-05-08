defmodule Kaffy.Resource do
  use Phoenix.HTML

  def excluded_fields(schema) do
    {field, _, _} = schema.__schema__(:autogenerate_id)
    [field]
  end

  def primary_keys(schema) do
    schema.__schema__(:primary_key)
  end

  def kaffy_field_name(schema, {field, options}) do
    default_name = to_string(field) |> String.capitalize()
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
      is_binary(value) -> value
      is_function(value) -> value.(schema)
      true -> default_value
    end
  end

  def kaffy_field_value(schema, field) when is_atom(field) do
    Map.get(schema, field, "")
  end

  def fields(schema) do
    all_fields =
      schema.__changeset__()
      |> Enum.filter(fn {_, v} -> is_atom(v) end)
      |> Enum.map(fn {k, _} -> k end)

    all_fields =
      if :id in all_fields do
        all_fields = all_fields -- [:id]
        [:id] ++ all_fields
      else
        all_fields
      end

    all_fields =
      if :inserted_at in all_fields do
        all_fields = all_fields -- [:inserted_at]
        all_fields ++ [:inserted_at]
      else
        all_fields
      end

    if :updated_at in all_fields do
      all_fields = all_fields -- [:updated_at]
      all_fields ++ [:updated_at]
    else
      all_fields
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
    case field_type(changeset.data.__struct__, field) do
      type -> build_html_input(changeset.data.__struct__, form, field, type, opts)
    end
  end

  defp build_html_input(schema, form, field, type, opts) do
    case type do
      :id ->
        text_or_assoc(schema, form, field, opts)

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
        text_input(form, field, opts)

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

  defp text_or_assoc(schema, form, field, opts) do
    IO.inspect(field)
    IO.inspect(associations(schema))
    field_no_id = to_string(field) |> String.slice(0..-4) |> String.to_existing_atom()

    case field_no_id in associations(schema) do
      true ->
        assoc = association_schema(schema, field_no_id)
        options = Kaffy.Utils.repo().all(assoc)

        string_fields = Enum.filter(fields(assoc), fn f -> field_type(assoc, f) == :string end)

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
end
