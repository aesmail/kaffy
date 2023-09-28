defmodule Kaffy.ResourceAdmin do
  alias Kaffy.ResourceSchema
  alias Kaffy.Utils

  @default_id_separator ":"

  @moduledoc """
  ResourceAdmin modules should be created for every schema you want to customize/configure in Kaffy.

  If you have a schema like `MyApp.Products.Product`, you should create an admin module with
  name `MyApp.Products.ProductAdmin` and add functions documented in this module to customize the behavior.

  All functions are optional.
  """

  @doc """
  Allows a description to be injected into the index view of a resource's index
  view. This is helpful when you want to provide information to the user about the index page.
  Return value can be a string, or {:safe, string) tuple.  If :safe tuple is used, HTML will be rendered.

  `index_description/1` takes a schema and must return a `String.t()` or tuple `{:safe, String.t()}`.

  If `index_description/1` is not defined, Kaffy will return nil.

  ## Examples:

  ```elixir
  def index_description(resource) do
    "This will show up on the index page."
  end

  def index_description(resource) do
    {:safe, "This will show up on the index page.  <b>This will be bold!</b>."}
  end
  ```
  """
  def index_description(resource) do
    Utils.get_assigned_value_or_default(
      resource,
      :index_description,
      ResourceSchema.index_description(resource)
    )
  end

  @doc """
  `index/1` takes the schema module and should return a keyword list of fields and
  their options.

  Supported options are `:name` and `:value`.

  Both options can be a string or an anonymous function.

  If a function is provided, the current entry is passed to it.

  If index/1 is not defined, Kaffy will return all the fields of the schema and their default values.

  ## Examples

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

  ## Examples

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
    |> set_default_field_options(schema)
  end

  defp set_default_field_options(fields, schema) do
    Enum.map(fields, fn {f, o} ->
      default_options = Kaffy.ResourceSchema.default_field_options(schema, f)
      final_options = Map.merge(default_options, o || %{})
      {f, final_options}
    end)
  end

  @doc """
  `search_fields/1` takes a schema and must return a list of `:string`, ':id`, `:integer`, and `:decimal` fields to search against when typing in the search box.

  If `search_fields/1` is not defined, Kaffy will return all the fields of the schema with the supported types mentioned earlier.

  ## Examples

  ```elixir
  def search_fields(_schema) do
    [:id, :title, :slug, :body, :price, :quantity]
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

  If `ordering/1` is not defined, Kaffy will return `[desc: primary_key]`, or the first field of the primary key, if it's a composite.

  ## Examples

  ```elixir
  def ordering(_schema) do
    [asc: :title]
  end
  ```
  """
  def ordering(resource) do
    schema = resource[:schema]
    [order_key | _] = ResourceSchema.primary_keys(schema)

    Utils.get_assigned_value_or_default(resource, :ordering, desc: order_key)
  end

  @doc """
  `default_actions/1` takes a schema and returns the default actions for the schema.

  If `default_actions/1` is not defined, Kaffy will return `[:new, :edit, :delete]`.

  Example:

  ```elixir
  def default_actions(_schema) do
    [:new, :delete]
  end
  ```
  """
  def default_actions(resource) do
    Utils.get_assigned_value_or_default(resource, :default_actions, [:new, :edit, :delete])
  end

  @doc """
  `authorized?/2` takes the schema and the current Plug.Conn struct and
  should return a boolean value.

  Returning false will prevent the access of this resource for the current user/request.

  If `authorized?/2` is not defined, Kaffy will return true.

  ## Examples

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

  ## Examples

  ```elixir
  def create_changeset(schema, attrs) do
    MyApp.Blog.Post.create_changeset(schema, attrs)
  end
  ```
  """
  def create_changeset(resource, changes) do
    schema = resource[:schema]
    schema_struct = schema.__struct__
    functions = schema.__info__(:functions)

    default =
      case Keyword.has_key?(functions, :changeset) do
        true ->
          schema.changeset(schema_struct, changes)

        false ->
          cast_fields = Kaffy.ResourceSchema.cast_fields(schema) |> Keyword.keys()
          Ecto.Changeset.cast(schema_struct, changes, cast_fields)
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

  ## Examples

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
        true ->
          schema.changeset(entry, changes)

        false ->
          cast_fields = Kaffy.ResourceSchema.cast_fields(schema) |> Keyword.keys()
          Ecto.Changeset.cast(entry, changes, cast_fields)
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

  ## Examples

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

  ## Examples

  ```elixir
  def plural_name(_schema) do
    "Categories"
  end
  ```
  """
  def plural_name(resource) do
    default = singular_name(resource) |> Kaffy.Inflector.pluralize()
    Utils.get_assigned_value_or_default(resource, :plural_name, default)
  end

  @doc """
  `serialize_id/2` takes a schema and record and must return a string to be used in the URL and form values.

  If `serialize_id/2` is not defined, Kaffy will concatenate multiple primary keys with `":"` as a separator.

  Examples:

  ```elixir
  # Default method with fixed keys
  def serialize_id(_schema, record) do
    Enum.join([record.post_id, record.tag_id], ":")
  end

  # ETF
  def serialize_id(_schema, record) do
    {record.post_id, record.tag_id}
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end
  ```
  """
  def serialize_id(resource, entry) do
    schema = resource[:schema]

    default =
      schema
      |> ResourceSchema.primary_keys()
      |> Enum.map_join(@default_id_separator, &Map.get(entry, &1))

    Utils.get_assigned_value_or_default(resource, :serialize_id, default, [entry])
  end

  @doc """
  `deserialize_id/2` takes a schema and serialized id and must return a complete
  keyword list in the form of [{:primary_key, value}, ...].

  If `deserialize_id/2` is not defined, Kaffy will split multiple primary keys with `":"` as a separator.

  Examples:

  ```elixir
  # Default method with fixed keys
  def deserialize_id(_schema, serialized_id) do
    Enum.zip([:post_id, :tag_id], String.split(serialized_id, ":"))
  end

  # Deserialize from ETF
  def deserialize_id(_schema, serialized_id) do
    {product_id, tag_id} = serialized_id
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()

    [product_id: product_id, tag_id: tag_id]
  end
  ```
  """
  def deserialize_id(resource, id) do
    schema = resource[:schema]
    id_list = String.split(id, @default_id_separator)

    default =
      schema
      |> ResourceSchema.primary_keys()
      |> Enum.zip(id_list)

    Utils.get_assigned_value_or_default(resource, :deserialize_id, default, [id])
  end

  def resource_actions(resource, conn) do
    Utils.get_assigned_value_or_default(resource, :resource_actions, nil, [conn], false)
  end

  def list_actions(resource, conn) do
    delete_action =
      case authorized?(resource, conn) && :delete in default_actions(resource) do
        true ->
          [
            delete_action: %{
              name: "Delete selected records",
              action: fn _, entries ->
                Kaffy.Utils.repo().transaction(fn ->
                  Enum.map(entries, fn entry ->
                    Kaffy.ResourceCallbacks.delete_callbacks(conn, resource, entry)
                  end)
                end)
                |> case do
                  {:ok, _} -> :ok
                  err -> err
                end
              end
            }
          ]

        false ->
          []
      end

    delete_action ++
      Utils.get_assigned_value_or_default(resource, :list_actions, [], [conn], false)
  end

  def widgets(resource, conn) do
    Utils.get_assigned_value_or_default(
      resource,
      :widgets,
      ResourceSchema.widgets(resource),
      [conn]
    )
  end

  def collect_widgets(conn, context \\ :kaffy_dashboard) do
    main_dashboard? = context == :kaffy_dashboard
    show_context_dashboard? = Kaffy.Utils.show_context_dashboards?()

    conn
    |> Kaffy.Utils.contexts()
    |> Enum.filter(fn c -> main_dashboard? or (show_context_dashboard? and c == context) end)
    |> Enum.reduce([], fn c, all ->
      widgets =
        Enum.reduce(Kaffy.Utils.schemas_for_context(conn, c), [], fn {_, resource}, all ->
          all ++ Kaffy.ResourceAdmin.widgets(resource, conn)
        end)
        |> Enum.map(fn widget ->
          width = Map.get(widget, :width)
          type = widget.type

          cond do
            is_nil(width) and type == "tidbit" -> Map.put(widget, :width, 3)
            is_nil(width) and type == "chart" -> Map.put(widget, :width, 12)
            is_nil(width) and type == "flash" -> Map.put(widget, :width, 4)
            true -> Map.put_new(widget, :width, 6)
          end
        end)

      all ++ widgets
    end)
    |> Enum.sort_by(fn w -> Map.get(w, :order, 999) end)
  end

  def custom_pages(resource, conn) do
    Utils.get_assigned_value_or_default(resource, :custom_pages, [], [conn])
  end

  def collect_pages(conn) do
    Enum.reduce(Kaffy.Utils.contexts(conn), [], fn c, all ->
      all ++
        Enum.reduce(Kaffy.Utils.schemas_for_context(conn, c), [], fn {_, resource}, all ->
          all ++ Kaffy.ResourceAdmin.custom_pages(resource, conn)
        end)
    end)
    |> Enum.sort_by(fn p -> Map.get(p, :order, 999) end)
  end

  def find_page(conn, slug) do
    conn
    |> collect_pages()
    |> Enum.filter(fn p -> p.slug == slug end)
    |> Enum.at(0)
  end

  def custom_links(resource, location \\ nil) do
    links = Utils.get_assigned_value_or_default(resource, :custom_links, [])

    case location do
      nil -> links
      :top -> Enum.filter(links, fn l -> Map.get(l, :location, :sub) == :top end)
      :sub -> Enum.filter(links, fn l -> Map.get(l, :location, :sub) == :sub end)
    end
    |> Enum.sort_by(fn l -> Map.get(l, :order, 999) end)
    |> Enum.map(fn l -> Map.merge(%{target: "_self", icon: "link", method: :get}, l) end)
  end

  def collect_links(conn, location) do
    contexts = Kaffy.Utils.contexts(conn)

    Enum.reduce(contexts, [], fn c, all ->
      resources = Kaffy.Utils.schemas_for_context(conn, c)

      Enum.reduce(resources, all, fn {_r, options}, all ->
        links =
          Kaffy.ResourceAdmin.custom_links(options)
          |> Enum.filter(fn link -> Map.get(link, :location, :sub) == location end)

        all ++ links
      end)
    end)
    |> Enum.sort_by(fn c -> Map.get(c, :order, 999) end)
  end

  def custom_index_query(conn, resource, query) do
    Utils.get_assigned_value_or_default(
      resource,
      :custom_index_query,
      query,
      [conn, resource[:schema], query],
      false
    )
  end

  def custom_show_query(conn, resource, query) do
    Utils.get_assigned_value_or_default(
      resource,
      :custom_show_query,
      query,
      [conn, resource[:schema], query],
      false
    )
  end
end
