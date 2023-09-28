defmodule Kaffy.ResourceCallbacks do
  @moduledoc false

  alias Kaffy.Utils

  def create_callbacks(conn, resource, changes) do
    changeset = Kaffy.ResourceAdmin.create_changeset(resource, changes)
    repo = Kaffy.Utils.repo()

    repo.transaction(fn ->
      result =
        with {:ok, changeset} <- before_insert(conn, resource, changeset),
             {:ok, changeset} <- before_save(conn, resource, changeset),
             {:ok, entry} <- exec_insert(conn, resource, changeset),
             {:ok, entry} <- after_save(conn, resource, entry),
             do: after_insert(conn, resource, entry)

      case result do
        {:ok, entry} -> entry
        {:error, changeset} -> repo.rollback(changeset)
        {:error, entry, error} -> repo.rollback({entry, error})
      end
    end)
  end

  defp exec_insert(conn, resource, changeset) do
    with {:ok, entry} <- insert(conn, resource, changeset) do
      {:ok, entry}
    else
      {:error, :not_found} ->
        Kaffy.Utils.repo().insert(changeset)

      {:error, error} ->
        {:error, error}

      unexpected_error ->
        {:error, unexpected_error}
    end
  end

  def update_callbacks(conn, resource, entry, changes) do
    changeset = Kaffy.ResourceAdmin.update_changeset(resource, entry, changes)
    repo = Kaffy.Utils.repo()

    repo.transaction(fn ->
      result =
        with {:ok, changeset} <- before_update(conn, resource, changeset),
             {:ok, changeset} <- before_save(conn, resource, changeset),
             {:ok, entry} <- exec_update(conn, resource, changeset),
             {:ok, entry} <- after_save(conn, resource, entry),
             do: after_update(conn, resource, entry)

      case result do
        {:ok, entry} -> entry
        {:error, changeset} -> repo.rollback(changeset)
        {:error, entry, error} -> repo.rollback({entry, error})
      end
    end)
  end

  defp exec_update(conn, resource, changeset) do
    with {:ok, entry} <- update(conn, resource, changeset) do
      {:ok, entry}
    else
      {:error, :not_found} ->
        Kaffy.Utils.repo().update(changeset)

      {:error, error} ->
        {:error, error}

      unexpected_error ->
        {:error, unexpected_error}
    end
  end

  def delete_callbacks(conn, resource, entry) do
    repo = Kaffy.Utils.repo()

    repo.transaction(fn ->
      result =
        with {:ok, changeset} <- before_delete(conn, resource, entry),
             {:ok, entry} <- exec_delete(conn, resource, changeset),
             do: after_delete(conn, resource, entry)

      case result do
        {:ok, entry} -> entry
        {:error, changeset} -> repo.rollback(changeset)
        {:error, entry, error} -> repo.rollback({entry, error})
      end
    end)
    |> case do
      {:ok, _} -> :ok
      err -> err
    end
  end

  defp before_insert(conn, resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :before_insert,
      {:ok, changeset},
      [conn, changeset],
      false
    )
  end

  defp insert(conn, resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :insert,
      {:error, :not_found},
      [conn, changeset],
      false
    )
  end

  defp after_insert(conn, resource, entry) do
    Utils.get_assigned_value_or_default(
      resource,
      :after_insert,
      {:ok, entry},
      [conn, entry],
      false
    )
  end

  defp before_update(conn, resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :before_update,
      {:ok, changeset},
      [conn, changeset],
      false
    )
  end

  defp before_save(conn, resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :before_save,
      {:ok, changeset},
      [conn, changeset],
      false
    )
  end

  defp after_save(conn, resource, entry) do
    Utils.get_assigned_value_or_default(resource, :after_save, {:ok, entry}, [conn, entry], false)
  end

  defp update(conn, resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :update,
      {:error, :not_found},
      [conn, changeset],
      false
    )
  end

  defp after_update(conn, resource, entry) do
    Utils.get_assigned_value_or_default(
      resource,
      :after_update,
      {:ok, entry},
      [conn, entry],
      false
    )
  end

  defp exec_delete(conn, resource, changeset) do
    with {:ok, entry} <- delete(conn, resource, changeset) do
      {:ok, entry}
    else
      {:error, :not_found} ->
        Kaffy.Utils.repo().delete(changeset)

      {:error, error} ->
        {:error, error}

      unexpected_error ->
        {:error, unexpected_error}
    end
  end

  defp before_delete(conn, resource, entry) do
    # changeset = Kaffy.ResourceAdmin.update_changeset(resource, entry, %{})
    changeset = Ecto.Changeset.change(entry)

    Utils.get_assigned_value_or_default(
      resource,
      :before_delete,
      {:ok, changeset},
      [conn, changeset],
      false
    )
  end

  defp delete(conn, resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :delete,
      {:error, :not_found},
      [conn, changeset],
      false
    )
  end

  defp after_delete(conn, resource, entry) do
    # changeset = Kaffy.ResourceAdmin.update_changeset(resource, entry, %{})

    Utils.get_assigned_value_or_default(
      resource,
      :after_delete,
      {:ok, entry},
      [conn, entry],
      false
    )
  end
end
