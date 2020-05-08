defmodule Kaffy.ResourceAdmin do
  alias Kaffy.Resource
  alias Kaffy.Utils

  def index(resource) do
    schema = resource[:schema]
    Utils.get_assigned_value_or_default(resource, :index, Resource.fields(schema))
  end

  def form_fields(resource) do
    schema = resource[:schema]
    Utils.get_assigned_value_or_default(resource, :form_fields, Resource.fields(schema))
  end

  def ordering(resource) do
    Utils.get_assigned_value_or_default(resource, :ordering, desc: :id)
  end

  def per_page(resource) do
    Utils.get_assigned_value_or_default(resource, :per_page, 100)
  end

  def search_fields(resource) do
    Utils.get_assigned_value_or_default(
      resource,
      :search_fields,
      Resource.search_fields(resource)
    )
  end

  def filter_fields(resource) do
    Utils.get_assigned_value_or_default(
      resource,
      :filter_fields,
      Resource.filter_fields(resource)
    )
  end

  def create_changeset(resource, changes) do
    schema = resource[:schema]
    functions = schema.__info__(:functions)

    default =
      case Keyword.has_key?(functions, :changeset) do
        true -> schema.changeset(schema.__struct__, changes)
        false -> Ecto.Changeset.change(schema.__struct__, changes)
      end

    Utils.get_assigned_value_or_default(
      resource,
      :create_changeset,
      default,
      [schema.__struct__, changes],
      false
    )
  end

  def update_changeset(resource, entry, changes) do
    schema = resource[:schema]
    functions = schema.__info__(:functions)

    default =
      case Keyword.has_key?(functions, :changeset) do
        true -> schema.changeset(entry, changes)
        false -> Ecto.Changeset.change(entry, changes)
      end

    Utils.get_assigned_value_or_default(
      resource,
      :update_changeset,
      default,
      [entry, changes],
      false
    )
  end

  def singular_name(resource) do
    default =
      resource[:schema]
      |> to_string()
      |> String.split(".")
      |> Enum.at(-1)

    Utils.get_assigned_value_or_default(resource, :singular_name, default)
  end

  def plural_name(resource) do
    default = singular_name(resource) <> "s"
    Utils.get_assigned_value_or_default(resource, :plural_name, default)
  end

  def authorized?(resource, conn) do
    Utils.get_assigned_value_or_default(resource, :authorized?, true, [conn])
  end
end
