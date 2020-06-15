defmodule Kaffy.ResourceError do
  use Phoenix.HTML

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
end
