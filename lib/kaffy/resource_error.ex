defmodule Kaffy.ResourceError do
  use PhoenixHTMLHelpers

  def form_error_border_class(form, default_class) do
    if Enum.count(form.errors) > 0 do
      "border-left-danger"
    else
      default_class
    end
  end

  def display_errors(conn, form) do
    errors =
      case length(form.errors) do
        0 ->
          []

        _x ->
          keys =
            Keyword.keys(form.errors)
            |> Enum.uniq()
            |> Enum.filter(fn x -> not is_field_in_form?(x, conn) end)

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
                    [
                      content_tag(:i, "", class: "fa fa-exclamation-circle"),
                      content_tag(:strong, "Error: "),
                      content_tag(:span, Kaffy.ResourceAdmin.humanize_term(field) <> " " <> msg)
                    ]
                  end
                end)
      end

    Enum.reduce(errors, [], fn error, combined ->
      Enum.reduce(error, combined, fn e, all -> [e | all] end)
    end)
  end

  defp is_field_in_form?(field, conn) do
    # check if field is part of the form, as we are showing inlines errors we don't want to show them twice.
    # This is needed as some field error might not be inlines, for instance for a required field from changetset that's not displayed in the form
    conn.params[conn.assigns.resource] |> Map.has_key?(Atom.to_string(field))
  end
end
