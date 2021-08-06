defmodule Kaffy.Utils do
  @moduledoc false

  @doc """
  Returns the :admin_title config if present, otherwise returns "Kaffy"
  """
  @spec title() :: String.t()
  def title() do
    env(:admin_title, "Kaffy")
  end

  @doc """
  Returns the static path to the asset.
  """
  @spec static_asset_path(Plug.Conn.t(), String.t()) :: String.t()
  def static_asset_path(conn, asset_path) do
    router().static_path(conn, asset_path)
  end

  @doc """
  Returns the :admin_logo config if present, otherwise returns Kaffy default logo.
  """
  @spec logo(Plug.Conn.t()) :: String.t()
  def logo(conn) do
    router().static_path(conn, env(:admin_logo, "/kaffy/assets/images/logo.png"))
  end

  @doc """
  Returns the :admin_logo_mini config if present, otherwise returns Kaffy default logo.
  """
  @spec logo_mini(Plug.Conn.t()) :: String.t()
  def logo_mini(conn) do
    router().static_path(conn, env(:admin_logo_mini, "/kaffy/assets/images/logo-mini.png"))
  end

  @doc """
  Returns the JSON package used by phoenix configs. If no such config exists, raise an exception.
  """
  @spec json() :: atom()
  def json() do
    case Application.get_env(:phoenix, :json_library) do
      nil ->
        raise "A json package must be configured. For example: config :phoenix, :json_library, Jason"

      j ->
        j
    end
  end

  @doc """
  Returns the Repo from Kaffy configs. If it is not present, raise an exception.
  """
  @spec repo() :: atom()
  def repo() do
    case env(:ecto_repo) do
      nil -> raise "Must define :ecto_repo for Kaffy to work properly."
      r -> r
    end
  end

  @doc """
  Returns the version of the provided app.

  Example:

    > get_version_of(:phoenix)
    > "1.5.3"
  """
  @spec get_version_of(atom()) :: String.t()
  def get_version_of(package) do
    {:ok, version} = :application.get_key(package, :vsn)
    to_string(version)
  end

  @doc """
  Returns true when phoenix's version has the same prefix as the provided argument, false otherwise.

  Example:

  phoenix_version?("1.4.")
  > true # returns true for all phoenix 1.4.x versions
  """
  @spec phoenix_version?(String.t()) :: boolean()
  def phoenix_version?(prefix) do
    version = get_version_of(:phoenix)
    String.starts_with?(version, prefix)
  end

  @doc """
  Returns the router helper module from the configs. Raises if the router isn't specified.
  """
  @spec router() :: atom()
  def router() do
    case env(:router) do
      nil -> raise "The :router config must be specified: config :kaffy, router: MyAppWeb.Router"
      r -> r
    end
    |> Module.concat(Helpers)
  end

  @doc """
  Returns a keyword list of all the resources specified in config.exs.

  If the :resources key isn't specified, this function will load all application modules,
  filters the schemas modules, combine them into a keyword list, and returns that list.

  Example:

  ```elixir
    full_resources()
    [
      categories: [
        schemas: [
          category: [
            schema: Bakery.Categories.Category,
            admin: Bakery.Categories.CategoryAdmin
          ]
        ]
      ]
    ]
  ```
  """
  @spec full_resources(Plug.Conn.t()) :: [any()]
  def full_resources(conn) do
    case env(:resources) do
      f when is_function(f) -> f.(conn)
      l when is_list(l) -> l
      _ -> setup_resources()
    end
  end

  @doc """
  Returns a list of contexts as atoms.

  Example:

      iex> contexts()
      [:blog, :products, :users]
  """
  @spec contexts(Plug.Conn.t()) :: [atom()]
  def contexts(conn) do
    full_resources(conn)
    |> Enum.map(fn {context, _options} -> context end)
  end

  @doc """
  Returns the context name based on the configs.

  Example:

  ```elixir
  context = [
      categories: [
        schemas: [
          category: [schema: Bakery.Categories.Category]
        ]
      ]
    ]

  context_name(context)
  > "Categories"

  context = [
      categories: [
        name: "Types",
        schemas: [
          category: [schema: Bakery.Categories.Category]
        ]
      ]
    ]

  context_name(context)
  > "Types"
  ```
  """
  @spec context_name(Plug.Conn.t(), list()) :: String.t()
  def context_name(conn, context) do
    default = Kaffy.ResourceAdmin.humanize_term(context)
    get_in(full_resources(conn), [context, :name]) || default
  end

  @doc """
  Returns the context list from the configs for a specific schema.

  This is usually used to get the name or other information of the schema context.
  """
  @spec get_context_for_schema(Plug.Conn.t(), module()) :: list()
  def get_context_for_schema(conn, schema) do
    contexts(conn)
    |> Enum.filter(fn c ->
      schemas = Enum.map(schemas_for_context(conn, c), fn {_k, v} -> Keyword.get(v, :schema) end)
      schema in schemas
    end)
    |> Enum.at(0)
  end

  def get_schema_key(conn, context, schema) do
    schemas_for_context(conn, context)
    |> Enum.reduce([], fn {k, v}, keys ->
      case schema == Keyword.get(v, :schema) do
        true -> [k | keys]
        false -> keys
      end
    end)
    |> Enum.at(0)
  end

  @doc """
  Returns the resource entry from the configs.

  Example:

      iex> get_resource("blog", "post")
      [schema: MyApp.Blog.Post, admin: MyApp.Blog.PostAdmin]
  """
  @spec get_resource(Plug.Conn.t(), String.t(), String.t()) :: list()
  def get_resource(conn, context, resource) do
    {context, resource} = convert_to_atoms(context, resource)
    get_in(full_resources(conn), [context, :resources, resource])
  end

  @doc """
  Returns all the schemas for the given context.

  Example:

      iex> schemas_for_context("blog")
      [
        post: [schema: MyApp.Blog.Post, admin: MyApp.Blog.PostAdmin],
        comment: [schema: MyApp.Blog.Comment],
      ]
  """
  @spec schemas_for_context(Plug.Conn.t(), list()) :: list()
  def schemas_for_context(conn, context) do
    context = convert_to_atom(context)
    get_in(full_resources(conn), [context, :resources])
  end

  # @doc """
  # Get the schema for the provided context/resource combination.

  #     iex> schema_for_resource("blog", "post")
  #     MyApp.Blog.Post
  # """
  # @spec schema_for_resource(String.t(), String.t()) :: module()
  # def schema_for_resource(context, resource) do
  #   {context, resource} = convert_to_atoms(context, resource)
  #   get_in(full_resources(), [context, :schemas, resource, :schema])
  # end

  # @doc """
  # Like schema_for_resource/2, but returns the admin module, or nil if an admin module doesn't exist.

  #     iex> admin-fro_resource("blog", "post")
  #     MyApp.Blog.PostAdmin
  # """
  # @spec admin_for_resource(String.t(), String.t()) :: module() | nil
  # def admin_for_resource(context, resource) do
  #   {context, resource} = convert_to_atoms(context, resource)
  #   get_in(full_resources(), [context, :schemas, resource, :admin])
  # end

  def get_assigned_value_or_default(resource, function, default, params \\ [], add_schema \\ true) do
    admin = resource[:admin]
    schema = resource[:schema]
    arguments = if add_schema, do: [schema] ++ params, else: params

    case !is_nil(admin) && has_function?(admin, function) do
      true -> apply(admin, function, arguments)
      false -> default
    end
  end

  @doc """
  Returns true if the given module implements the given function, false otherwise.

      iex> has_function?(MyApp.Blog.PostAdmin, :form_fields)
      true
  """
  @spec has_function?(module(), atom()) :: boolean()
  def has_function?(admin, func) do
    functions = admin.__info__(:functions)
    Keyword.has_key?(functions, func)
  end

  @doc """
  Returns true if `thing` is a module, false otherwise.
  """
  @spec is_module(module()) :: boolean()
  def is_module(thing), do: is_atom(thing) && function_exported?(thing, :__info__, 1)

  @doc """
  Returns whether the dashbaord link should be displayed or hidden. Default behavior is to show the dashboard link.
  This option is taken from the :hide_dashboard config option.

      iex> show_dashboard?()
      true
  """
  @spec show_dashboard?() :: boolean()
  def show_dashboard?() do
    env(:hide_dashboard, false) == false
  end

  @doc """
  Takes a conn struct and returns the route to display as the root route.

  This option can be optionally provided in the configs. If it is not provided, the default route is the dashboard.

  Options are:

  - [kaffy: :dashboard]
  - [schema: ["blog", "post"]]
  - [page: "my-custom-page"]

      iex> home_page(conn)
      "/admin/dashboard"
  """
  @spec home_page(Plug.Conn.t()) :: String.t()
  def home_page(conn) do
    case env(:home_page, kaffy: :dashboard) do
      [kaffy: :dashboard] ->
        router().kaffy_dashboard_path(conn, :dashboard)

      [schema: [context, resource]] ->
        router().kaffy_resource_path(conn, :index, context, resource)

      [page: slug] ->
        router().kaffy_page_path(conn, :index, slug)
    end
  end

  def extensions(conn) do
    exts = env(:extensions, [])

    stylesheets =
      Enum.map(exts, fn ext ->
        case function_exported?(ext, :stylesheets, 1) do
          true -> ext.stylesheets(conn)
          false -> []
        end
      end)

    javascripts =
      Enum.map(exts, fn ext ->
        case function_exported?(ext, :javascripts, 1) do
          true -> ext.javascripts(conn)
          false -> []
        end
      end)

    %{stylesheets: stylesheets, javascripts: javascripts}
  end

  defp env(key, default \\ nil) do
    Application.get_env(:kaffy, key, default)
  end

  defp convert_to_atoms(context, resource) do
    {convert_to_atom(context), convert_to_atom(resource)}
  end

  defp convert_to_atom(string) do
    if is_binary(string), do: String.to_existing_atom(string), else: string
  end

  defp setup_resources do
    otp_app = env(:otp_app)
    {:ok, mods} = :application.get_key(otp_app, :modules)

    get_schemas(mods)
    |> build_resources()
  end

  defp get_schemas(mods) do
    Enum.filter(mods, fn m ->
      functions = m.__info__(:functions)
      Keyword.has_key?(functions, :__schema__) && Map.has_key?(m.__struct__, :__meta__)
    end)
  end

  defp build_resources(schemas) do
    Enum.reduce(schemas, [], fn schema, resources ->
      schema_module =
        to_string(schema)
        |> String.split(".")

      context_module =
        schema_module
        |> Enum.reverse()
        |> tl()
        |> Enum.reverse()
        |> Enum.join(".")

      context_name =
        schema_module
        |> Enum.at(-2)
        |> Macro.underscore()
        |> String.to_atom()

      schema_name_string =
        schema_module
        |> Enum.at(-1)

      schema_name =
        schema_name_string
        |> Macro.underscore()
        |> String.to_atom()

      schema_admin = String.to_atom("#{context_module}.#{schema_name_string}Admin")

      schema_options =
        case function_exported?(schema_admin, :__info__, 1) do
          true -> [schema: schema, admin: schema_admin]
          false -> [schema: schema]
        end

      humanized_context = Kaffy.ResourceAdmin.humanize_term(context_name)
      resources = Keyword.put_new(resources, context_name, name: humanized_context, resources: [])
      resources = put_in(resources, [context_name, :resources, schema_name], schema_options)
      existing_schemas = get_in(resources, [context_name, :resources]) |> Enum.sort()
      put_in(resources, [context_name, :resources], existing_schemas)
    end)
    |> Enum.sort()
  end

  def get_task_modules() do
    env(:scheduled_tasks, [])
  end
end
