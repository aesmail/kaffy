defmodule Kaffy.ResourceCallbacks do
  @moduledoc false

  alias Kaffy.Utils

  def create_callbacks(resource, changes) do
    changeset = Kaffy.ResourceAdmin.create_changeset(resource, changes)

    Kaffy.Utils.repo().transaction(fn repo ->
      result =
        with {:ok, changeset} <- before_create(resource, changeset),
             {:ok, changeset} <- before_save(resource, changeset),
             {:ok, entry} <- Kaffy.Utils.repo().insert(changeset),
             {:ok, entry} <- after_save(resource, entry),
             do: after_create(resource, entry)

      case result do
        {:ok, entry} -> entry
        {:error, changeset} -> repo.rollback(changeset)
        {:error, entry, error} -> repo.rollback({entry, error})
      end
    end)
  end

  def update_callbacks(resource, entry, changes) do
    changeset = Kaffy.ResourceAdmin.update_changeset(resource, entry, changes)

    Kaffy.Utils.repo().transaction(fn repo ->
      result =
        with {:ok, changeset} <- before_update(resource, changeset),
             {:ok, changeset} <- before_save(resource, changeset),
             {:ok, entry} <- Kaffy.Utils.repo().update(changeset),
             {:ok, entry} <- after_save(resource, entry),
             do: after_update(resource, entry)

      case result do
        {:ok, entry} -> entry
        {:error, changeset} -> repo.rollback(changeset)
        {:error, entry, error} -> repo.rollback({entry, error})
      end
    end)
  end

  def delete_callbacks(resource, entry) do
    Kaffy.Utils.repo().transaction(fn repo ->
      result =
        with {:ok, entry} <- before_delete(resource, entry),
             {:ok, entry} <- Kaffy.Utils.repo().delete(entry),
             do: after_delete(resource, entry)

      case result do
        {:ok, entry} -> entry
        {:error, changeset} -> repo.rollback(changeset)
        {:error, entry, error} -> repo.rollback({entry, error})
      end
    end)
  end

  defp before_create(resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :before_create,
      {:ok, changeset},
      [changeset],
      false
    )
  end

  defp after_create(resource, entry) do
    Utils.get_assigned_value_or_default(resource, :after_create, {:ok, entry}, [entry], false)
  end

  defp before_update(resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :before_update,
      {:ok, changeset},
      [changeset],
      false
    )
  end

  defp before_save(resource, changeset) do
    Utils.get_assigned_value_or_default(
      resource,
      :before_save,
      {:ok, changeset},
      [changeset],
      false
    )
  end

  defp after_save(resource, entry) do
    Utils.get_assigned_value_or_default(resource, :after_save, {:ok, entry}, [entry], false)
  end

  defp after_update(resource, entry) do
    Utils.get_assigned_value_or_default(resource, :after_update, {:ok, entry}, [entry], false)
  end

  defp before_delete(resource, entry) do
    Utils.get_assigned_value_or_default(resource, :before_delete, {:ok, entry}, [entry], false)
  end

  defp after_delete(resource, entry) do
    Utils.get_assigned_value_or_default(resource, :after_delete, {:ok, entry}, [entry], false)
  end
end
