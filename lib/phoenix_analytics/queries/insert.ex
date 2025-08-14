defmodule PhoenixAnalytics.Queries.Insert do
  @moduledoc """
  Ecto-based insert operations for PhoenixAnalytics.

  This module provides functions for inserting RequestLog entries
  using Ecto's insert and insert_all functions.
  """

  alias PhoenixAnalytics.Entities.RequestLog

  @doc """
  Inserts a single RequestLog entry using Ecto.
  """
  @spec insert_one(RequestLog.t()) :: {:ok, RequestLog.t()} | {:error, Ecto.Changeset.t()}
  def insert_one(%RequestLog{} = request_data) do
    # Create a changeset and insert
    changeset = RequestLog.changeset(%RequestLog{}, Map.from_struct(request_data))
    repo = PhoenixAnalytics.Config.get_repo()
    repo.insert(changeset)
  end

  @doc """
  Inserts multiple RequestLog entries using Ecto's insert_all.
  """
  @spec insert_many(list(RequestLog.t())) :: {:ok, integer()} | {:error, term()}
  def insert_many(request_data_list) when is_list(request_data_list) do
    # Convert structs to maps for insert_all
    records =
      Enum.map(request_data_list, fn request_log ->
        Map.from_struct(request_log)
      end)

    # Use insert_all for better performance
    repo = PhoenixAnalytics.Config.get_repo()

    case repo.insert_all(RequestLog, records, returning: [:request_id]) do
      {:ok, result} -> {:ok, result.num_rows}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Inserts a single RequestLog entry with a custom changeset.
  """
  @spec insert_one_with_changeset(Ecto.Changeset.t()) ::
          {:ok, RequestLog.t()} | {:error, Ecto.Changeset.t()}
  def insert_one_with_changeset(%Ecto.Changeset{} = changeset) do
    repo = PhoenixAnalytics.Config.get_repo()
    repo.insert(changeset)
  end

  @doc """
  Inserts multiple RequestLog entries with custom changesets.
  """
  @spec insert_many_with_changesets(list(Ecto.Changeset.t())) ::
          {:ok, integer()} | {:error, term()}
  def insert_many_with_changesets(changesets) when is_list(changesets) do
    # For changesets, we need to insert them one by one
    # since insert_all doesn't work with changesets
    repo = PhoenixAnalytics.Config.get_repo()
    results = Enum.map(changesets, &repo.insert/1)

    # Check if all inserts were successful
    case Enum.find(results, fn
           {:ok, _} -> false
           {:error, _} -> true
         end) do
      nil ->
        # All successful
        {:ok, length(results)}

      {:error, reason} ->
        # At least one failed
        {:error, reason}
    end
  end

  @doc """
  Upserts a RequestLog entry (insert if not exists, update if exists).
  """
  @spec upsert_one(RequestLog.t()) :: {:ok, RequestLog.t()} | {:error, term()}
  def upsert_one(%RequestLog{} = request_data) do
    changeset = RequestLog.changeset(%RequestLog{}, Map.from_struct(request_data))

    # Use repo.insert with on_conflict for upsert behavior
    repo = PhoenixAnalytics.Config.get_repo()

    repo.insert(changeset,
      on_conflict: :replace_all,
      conflict_target: [:request_id]
    )
  end

  @doc """
  Bulk upserts multiple RequestLog entries.
  """
  @spec upsert_many(list(RequestLog.t())) :: {:ok, integer()} | {:error, term()}
  def upsert_many(request_data_list) when is_list(request_data_list) do
    records =
      Enum.map(request_data_list, fn request_log ->
        Map.from_struct(request_log)
      end)

    # Use insert_all with on_conflict for bulk upsert
    repo = PhoenixAnalytics.Config.get_repo()

    case repo.insert_all(RequestLog, records,
           on_conflict: :replace_all,
           conflict_target: [:request_id],
           returning: [:request_id]
         ) do
      {:ok, result} -> {:ok, result.num_rows}
      {:error, reason} -> {:error, reason}
    end
  end
end
