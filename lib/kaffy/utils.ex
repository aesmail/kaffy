defmodule Kaffy.Utils do
  @moduledoc false

  def title do
    env(:admin_title, "Kaffy")
  end

  def json() do
    Application.get_env(:phoenix, :json_library, Jason)
  end

  def repo do
    env(:ecto_repo)
  end

  def get_version_of(package) do
    {:ok, version} = :application.get_key(package, :vsn)
    to_string(version)
  end

  def phoenix_1_4?() do
    version = get_version_of(:phoenix)
    String.starts_with?(version, "1.4.")
  end

  def router do
    Module.concat(env(:router), Helpers)
  end

  def full_resources() do
    env(:resources, setup_resources())
  end

  def contexts() do
    full_resources()
    |> Keyword.keys()
  end

  def context_name(context) do
    default = to_string(context) |> String.capitalize()
    get_in(full_resources(), [context, :name]) || default
  end

  def get_context_for_schema(schema) do
    contexts()
    |> Enum.filter(fn c ->
      schemas = Enum.map(schemas_for_context(c), fn {_k, v} -> Keyword.get(v, :schema) end)
      schema in schemas
    end)
    |> Enum.at(0)
  end

  def get_schema_key(context, schema) do
    schemas_for_context(context)
    |> Enum.reduce([], fn {k, v}, keys ->
      case schema == Keyword.get(v, :schema) do
        true -> [k | keys]
        false -> keys
      end
    end)
    |> Enum.at(0)
  end

  def get_resource(context, resource) do
    {context, resource} = convert_to_atoms(context, resource)
    get_in(full_resources(), [context, :schemas, resource])
  end

  def schemas_for_context(context) do
    context = convert_to_atom(context)
    get_in(full_resources(), [context, :schemas])
  end

  def schema_for_resource(context, resource) do
    {context, resource} = convert_to_atoms(context, resource)
    get_in(full_resources(), [context, :schemas, resource, :schema])
  end

  def admin_for_resource(context, resource) do
    {context, resource} = convert_to_atoms(context, resource)
    get_in(full_resources(), [context, :schemas, resource, :admin])
  end

  def get_assigned_value_or_default(resource, function, default, params \\ [], add_schema \\ true) do
    admin = resource[:admin]
    schema = resource[:schema]
    arguments = if add_schema, do: [schema] ++ params, else: params

    case !is_nil(admin) && has_function?(admin, function) do
      true -> apply(admin, function, arguments)
      false -> default
    end
  end

  def has_function?(admin, func) do
    functions = admin.__info__(:functions)
    Keyword.has_key?(functions, func)
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

  def setup_resources do
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
        |> String.downcase()
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

      resources = Keyword.put_new(resources, context_name, schemas: [])
      resources = put_in(resources, [context_name, :schemas, schema_name], schema_options)
      existing_schemas = get_in(resources, [context_name, :schemas]) |> Enum.sort()
      put_in(resources, [context_name, :schemas], existing_schemas)
    end)
    |> Enum.sort()
  end

  @doc """
  Convert date string to utc_datetime


  TODO: We will need to handle the date type bellow:
  :date           -> ~D[2010-04-17]
  :time           -> ~T[14:00:00]
  :time_usec      -> ~T[14:00:00.000000]
  :utc_datetime   -> ~U[2010-04-17T14:00:00Z]
  :utc_datetime_usec -> ~U[2010-04-17T14:00:00.000000Z]
  :naive_datetime -> ~N[2010-04-17 14:00:00]
  :naive_datetime_usec -> ~N[2010-04-17 14:00:00.000000]

  """
  def string_to_utc_datetime(date_string) do
    # date_string = "2020-06-10 12:00"
    date_string = date_string |> String.replace(" ", "T")
    date_string = "#{date_string}:00Z"
    {:ok, utc_datetime, _} = DateTime.from_iso8601(date_string)
    utc_datetime
  end
end
