defmodule Kaffy.Adapters.Data.DataProtocol do
  @callback resources(Plug.Conn.t()) :: {:ok, [map()]} | {:error, map()}
  @callback get_resource(Plug.Conn.t()) :: {:ok, map()} | {:error, map()}
  @callback list(Plug.Conn.t()) :: {:ok, [map()]} | {:error, map()}
  @callback show(Plug.Conn.t()) :: {:ok, map()} | {:error, map()}
  @callback new(Plug.Conn.t()) :: {:ok, map()} | {:error, map()}
  @callback create(Plug.Conn.t()) :: {:ok, map()} | {:error, map()}
  @callback edit(Plug.Conn.t()) :: {:ok, map()} | {:error, map()}
  @callback update(Plug.Conn.t()) :: {:ok, map()} | {:error, map()}
  @callback delete(Plug.Conn.t()) :: {:ok, map()} | {:error, map()}
end
