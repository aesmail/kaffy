defmodule Kaffy.ResourceAdmin do
  alias Kaffy.ResourceSchema
  alias Kaffy.Utils

  @moduledoc """
  ResourceAdmin modules should be created for every schema you want to customize/configure in Kaffy.

  If you have a schema like `MyApp.Products.Product`, you should create an admin module with
  name `MyApp.Products.ProductAdmin` and add functions documented in this module to customize the behavior.

  All functions are optional.
  """

  @doc """
  `index/1` takes the schema module and should return a keyword list of fields and
  their options.

  Supported options are `:name` and `:value`.

  Both options can be a string or an anonymous function.

  If a fuction is provided, the current entry is passed to it.

  If index/1 is not defined, Kaffy will return all the fields of the schema and their default values.

  Example:

  ```elixir
  def index(_schema) do
    [
      id: %{name: "ID", value: fn post -> post.id + 100 end},
      title: nil, # this will render the default name for this field (Title) and its default value (post.title)
      views: %{name: "Hits", value: fn post -> post.views + 10 end},
      published: %{name: "Published?", value: fn post -> published?(post) end},
      comment_count: %{name: "Comments", value: fn post -> comment_count(post) end}
    ]
  end
  ```
  """
  def index(resource) do
    schema = resource[:schema]
    Utils.get_assigned_value_or_default(resource, :index, ResourceSchema.index_fields(schema))
  end

  @doc """
  form_fields/1 takes a schema and returns a keyword list of fields and their options for the new/edit form.

  Supported options are:

  `:label`, `:type`, `:choices`, and `:permission`

  `:type` can be any ecto type in addition to `:file` and `:textarea`

  If `:choices` is provided, it must be a keyword list and
  the field will be rendered as a `<select>` element regardless of the actual field type.

  Setting `:permission` to `:read` will make the field non-editable. It is `:write` by default.

  If you want to remove a field from being rendered, just remove it from the list.

  If form_fields/1 is not defined, Kaffy will return all the fields with
  their default types based on the schema.

  Example:

  ```elixir
  def form_fields(_schema) do
    [
      title: %{label: "Subject"},
      slug: nil,
      image: %{type: :file},
      status: %{choices: [{"Pending", "pending"}, {"Published", "published"}]},
      body: %{type: :textarea, rows: 3},
      views: %{permission: :read}
    ]
  end
  ```
  """
  def form_fields(resource) do
    schema = resource[:schema]

    Utils.get_assigned_value_or_default(
      resource,
      :form_fields,
      ResourceSchema.form_fields(schema)
    )
  end

  @doc """
  `search_fields/1` takes a schema and must return a list of `:string` fields to search against when typing in the search box.

  If `search_fields/1` is not defined, Kaffy will return all the `:string` fields of the schema.

  Example:

  ```elixir
  def search_fields(_schema) do
    [:title, :slug, :body]
  end
  ```
  """
  def search_fields(resource) do
    Utils.get_assigned_value_or_default(
      resource,
      :search_fields,
      ResourceSchema.search_fields(resource)
    )
  end

  @doc """
  `ordering/1` takes a schema and returns how the entries should be ordered.

  If `ordering/1` is not defined, Kaffy will return `[desc: :id]`.

  Example:

  ```elixir
  def ordering(_schema) do
    [asc: :title]
  end
  ```
  """
  def ordering(resource) do
    Utils.get_assigned_value_or_default(resource, :ordering, desc: :id)
  end

  @doc """
  `authorized?/2` takes the schema and the current Plug.Conn struct and
  should return a boolean value.

  Returning false will prevent the access of this resource for the current user/request.

  If `authorized?/2` is not defined, Kaffy will return true.

  Example:

  ```elixir
  def authorized?(_schema, _conn) do
    true
  end
  ```
  """
  def authorized?(resource, conn) do
    Utils.get_assigned_value_or_default(resource, :authorized?, true, [conn])
  end

  @doc """
  `create_changeset/2` takes the record and the changes and should return a changeset for creating a new record.

  If `create_changeset/2` is not defined, Kaffy will try to call `schema.changeset/2`

  and if that's not defined, `Ecto.Changeset.change/2` will be called.

  Example:

  ```elixir
  def create_changeset(schema, attrs) do
    MyApp.Blog.Post.create_changeset(schema, attrs)
  end
  ```
  """
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

  @doc """
  `update_changeset/2` takes the record and the changes and should return a changeset for updating an existing record.

  If `update_changeset/2` is not defined, Kaffy will try to call `schema.changeset/2`

  and if that's not defined, `Ecto.Changeset.change/2` will be called.

  Example:

  ```elixir
  def update_changeset(schema, attrs) do
    MyApp.Blog.Post.create_changeset(schema, attrs)
  end
  ```
  """
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

  @doc """
  This function should return a string for the singular name of a resource.

  If `singular_name/1` is not defined, Kaffy will use the name of
  the last part of the schema module (e.g. Post in MyApp.Blog.Post)

  This is useful for when you have a schema but you want to display its name differently.

  If you have "Post" and you want to display "Article" for example.

  Example:

  ```elixir
  def singular_name(_schema) do
    "Article"
  end
  ```
  """
  def singular_name(resource) do
    default = humanize_term(resource[:schema])
    Utils.get_assigned_value_or_default(resource, :singular_name, default)
  end

  def humanize_term(term) do
    term
    |> to_string()
    |> String.split(".")
    |> Enum.at(-1)
    |> Macro.underscore()
    |> String.split("_")
    |> Enum.map(fn s -> String.capitalize(s) end)
    |> Enum.join(" ")
  end

  @doc """
  This is useful for names that cannot be plural by adding an "s" at the end.

  Like "Category" => "Categories" or "Person" => "People".

  If `plural_name/1` is not defined, Kaffy will use the singular
  name and add an "s" to it (e.g. Posts).

  Example:

  ```elixir
  def plural_name(_schema) do
    "Categories"
  end
  ```
  """
  def plural_name(resource) do
    default = singular_name(resource) <> "s"
    Utils.get_assigned_value_or_default(resource, :plural_name, default)
  end

  def resource_actions(resource, conn) do
    Utils.get_assigned_value_or_default(resource, :resource_actions, nil, [conn], false)
  end

  def list_actions(resource, conn) do
    Utils.get_assigned_value_or_default(resource, :list_actions, nil, [conn], false)
  end

  def widgets(resource, conn) do
    Utils.get_assigned_value_or_default(
      resource,
      :widgets,
      ResourceSchema.widgets(resource),
      [conn]
    )
  end

  def collect_widgets(conn) do
    Enum.reduce(Kaffy.Utils.contexts(), [], fn c, all ->
      widgets =
        Enum.reduce(Kaffy.Utils.schemas_for_context(c), [], fn {_, resource}, all ->
          all ++ Kaffy.ResourceAdmin.widgets(resource, conn)
        end)

      all ++ widgets
    end)
    |> Enum.sort_by(fn w -> Map.get(w, :order, 999) end)
  end

  def scheduled_tasks(resource) do
    Utils.get_assigned_value_or_default(resource, :scheduled_tasks, [])
  end

  def collect_tasks() do
    Enum.reduce(Kaffy.Utils.contexts(), [], fn c, all ->
      tasks =
        Enum.reduce(Kaffy.Utils.schemas_for_context(c), [], fn {_, resource}, all ->
          all ++ Kaffy.ResourceAdmin.scheduled_tasks(resource)
        end)

      all ++ tasks
    end)
  end

  def tasks_info() do
    children = DynamicSupervisor.which_children(KaffyTaskSupervisor)

    Enum.map(children, fn {_, p, _, _} ->
      GenServer.call(p, :info)
    end)
  end
end
