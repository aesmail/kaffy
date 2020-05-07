defmodule Kaffy.Utils do
  def title do
    env(:admin_title, "Kaffy")
  end

  def repo do
    env(:ecto_repo)
  end

  def router do
    Module.concat(env(:router), Helpers)
  end

  def contexts() do
    env(:resources, [])
    |> Keyword.keys()
  end

  def context_name(context) do
    default = to_string(context) |> String.capitalize()
    get_in(env(:resources, []), [context, :name]) || default
  end

  def get_resource(context, resource) do
    {context, resource} = convert_to_atoms(context, resource)
    get_in(env(:resources, []), [context, :schemas, resource])
  end

  def schemas_for_context(context) do
    context = convert_to_atom(context)
    get_in(env(:resources, []), [context, :schemas])
  end

  def schema_for_resource(context, resource) do
    {context, resource} = convert_to_atoms(context, resource)
    get_in(env(:resources, []), [context, :schemas, resource, :schema])
  end

  def admin_for_resource(context, resource) do
    {context, resource} = convert_to_atoms(context, resource)
    get_in(env(:resources, []), [context, :schemas, resource, :admin])
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
end
