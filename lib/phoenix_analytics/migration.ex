defmodule PhoenixAnalytics.Migration do
  @moduledoc false

  @doc """
  Creates the requests table using Ecto migrations.
  """
  def up do
    # Create the table using Ecto
    create_table_query = """
    CREATE TABLE IF NOT EXISTS requests (
      request_id VARCHAR(255) PRIMARY KEY,
      method VARCHAR(10) NOT NULL,
      path TEXT NOT NULL,
      status_code INTEGER NOT NULL,
      duration_ms INTEGER NOT NULL,
      user_agent TEXT,
      remote_ip VARCHAR(45),
      referer TEXT,
      device_type VARCHAR(20),
      session_id VARCHAR(255),
      session_page_views INTEGER,
      inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """

    repo = PhoenixAnalytics.Config.get_repo()
    case repo.query(create_table_query) do
      {:ok, _result} ->
        IO.puts("Migration applied: requests table created")
        {:ok, "Table created successfully"}

      {:error, reason} ->
        IO.puts("Failed to apply migration: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Drops the requests table.
  """
  def down do
    drop_table_query = "DROP TABLE IF EXISTS requests;"

    repo = PhoenixAnalytics.Config.get_repo()
    case repo.query(drop_table_query) do
      {:ok, _result} ->
        IO.puts("Migration rolled back: requests table dropped")
        {:ok, "Table dropped successfully"}

      {:error, reason} ->
        IO.puts("Failed to roll back migration: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Creates the requests table using Ecto schema.
  """
  def create_table_ecto do
    # This would be used if you want to use Ecto's create table functionality
    # For now, we'll use raw SQL for better database compatibility
    up()
  end
end
