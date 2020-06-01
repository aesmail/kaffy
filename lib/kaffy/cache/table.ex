defmodule Kaffy.Cache.Table do
  @moduledoc false

  @table_name :kaffy_cache
  @expire_suffix "_expires"

  @doc """
  Prepare keys and add key value to the cache
  """
  def add_to_cache(key, suffix, value, expire_after \\ 600) do
    string_key = stringify_key([key, suffix])
    expiration_key = stringify_key([key, suffix, @expire_suffix])
    expiration_date = DateTime.utc_now() |> DateTime.add(expire_after)
    cache_value(string_key, value)
    cache_value(expiration_key, expiration_date)
  end

  @doc false
  defp cache_value(key, value) do
    create_table(@table_name)
    :ets.insert(@table_name, {key, value})
  end

  @doc """
  Create a new ETS table if undefined
  """
  def create_table(name \\ @table_name) do
    case :ets.info(name) do
      :undefined -> :ets.new(name, [:named_table])
      ref -> ref
    end
  end

  @doc """
  Get value from the cache ETS table, check if the key is expired
  return nil if key doesn't exist or if it's expired
  """
  def get_from_cache(key, suffix) do
    create_table(@table_name)
    final_key = stringify_key([key, suffix])
    expiration_key = stringify_key([key, suffix, @expire_suffix])

    case :ets.lookup(@table_name, final_key) do
      [] ->
        nil

      [{_k, value}] ->
        case :ets.lookup(@table_name, expiration_key) do
          [] ->
            :ets.delete(@table_name, final_key)
            :ets.delete(@table_name, expiration_key)
            nil

          [{_, expiration_date}] ->
            now = DateTime.utc_now()

            case DateTime.compare(expiration_date, now) do
              :lt ->
                :ets.delete(@table_name, final_key)
                :ets.delete(@table_name, expiration_key)
                nil

              _eq_or_gt ->
                value
            end
        end
    end
  end

  @doc false
  defp stringify_key(list), do: list |> Enum.map(fn x -> to_string(x) end) |> Enum.join("_")
end
