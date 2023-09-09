defmodule Kaffy.ResourceFormTest do
  use ExUnit.Case, async: true
  alias Kaffy.ResourceForm
  alias Fixtures.TravelSchema

  describe "form_field/4" do
    test "render string field" do
      html = render_field(:title)
      assert html =~ ~r/dummy\[title]/
      assert html =~ ~r/^<input/
      assert html =~ ~r/type="text"/
    end

    test "render integer field" do
      html = render_field(:number_of_people)
      assert html =~ ~r/dummy\[number_of_people]/
      assert html =~ ~r/^<input/
      assert html =~ ~r/type="number"/
    end

    test "render boolean field" do
      html = render_field(:requires_passport)
      assert html =~ ~r/dummy\[requires_passport]/
      assert html =~ ~r/type="checkbox"/
    end

    test "render UTC datetime field" do
      html = render_field(:start_time)
      assert html =~ ~r/dummy\[start_time\]/
      assert html =~ ~r/flatpickr-wrap-datetime/
    end

    test "render naive datetime field" do
      html = render_field(:local_start_time)
      assert html =~ ~r/dummy\[local_start_time\]/
      assert html =~ ~r/flatpickr-wrap-datetime/
    end

    test "render date field" do
      html = render_field(:end_date)
      assert html =~ ~r/dummy\[end_date]/
      assert html =~ ~r/flatpickr-wrap-date/
    end

    test "render array field" do
      html = render_field(:age_of_travelers)
      assert html =~ ~r/^<textarea/
    end

    test "render enum field" do
      html = render_field(:travel_type)
      assert html =~ ~r/dummy\[travel_type]/
      assert html =~ ~r/^<select/
      assert html =~ ~r/<option value="other">Other<\/option>/
    end

    test "render enum array field" do
      html = render_field(:means_of_transport)
      assert html =~ ~r/dummy\[means_of_transport]/
      assert html =~ ~r/^<select id="dummy_means_of_transport" multiple/
      assert html =~ ~r/<option value="ferry">Ferry<\/option>/
    end

    test "render embed" do
      html = render_field(:metadata)
      assert html =~ ~r/div class="form-group"/
      assert html =~ ~r/dummy\[metadata\]\[travelforce_id]/
    end

    test "render embed of many" do
      html = render_field(:stays, schema: %TravelSchema{stays: []})
      # textarea with json is probably a temporary solution
      assert html =~ ~r/^<textarea/
      assert html =~ ~r/\[\]<\/textarea>/
    end

    test "render richtext field" do
      html = render_field(:description, field_opts: %{type: :richtext})
      assert html =~ ~r/^<textarea/
      assert html =~ ~r/class="kaffy-editor"/
    end
  end

  def render_field(name, opts \\ Keyword.new()) do
    schema = Keyword.get(opts, :schema, %TravelSchema{})
    field_opts = Keyword.get(opts, :field_opts, %{})

    changeset = Ecto.Changeset.change(schema, %{})

    form = Phoenix.HTML.FormData.to_form(changeset.changes, as: :dummy)
    ast = ResourceForm.form_field(changeset, form, {name, field_opts})

    case ast do
      list when is_list(list) ->
        Enum.map(list, &Phoenix.HTML.safe_to_string/1)
        |> Enum.reduce("", fn acc, str -> acc <> str end)

      {:safe, _} ->
        Phoenix.HTML.safe_to_string(ast)
    end
  end
end
