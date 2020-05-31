defmodule Kaffy.Cache.Table do
  @moduledoc false

  @table_name :kaffy_cache
  @expire_suffix "_expires"

  def add_to_cache(key, postfix, value, expire_after \\ 600) do
    value_key = stringify_key(key, postfix)
    expiration_key = stringify_key(key, postfix, @expire_suffix)
    expiration_value = DateTime.utc_now() |> DateTime.add(expire_after)
    cache_value(value_key, value)
    cache_value(expiration_key, expiration_value)
  end

  defp cache_value(key, value) do
    create_table(@table_name)
    :ets.insert(@table_name, {key, value})
  end

  def create_table(name \\ @table_name) do
    case :ets.info(name) do
      :undefined -> :ets.new(name, [:named_table])
      ref -> ref
    end
  end

  def get_from_cache(key, postfix) do
    create_table(@table_name)
    final_key = stringify_key(key, postfix)
    expiration_key = stringify_key(key, postfix, @expire_suffix)

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

  defp stringify_key(key, postfix, extra \\ "") do
    temp = to_string(key) <> "_" <> to_string(postfix)

    if extra == "" do
      temp
    else
      temp <> "_" <> to_string(extra)
    end
  end
end
