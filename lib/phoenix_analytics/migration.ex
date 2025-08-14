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
  Adds database indexes for optimal query performance.

  Creates indexes on frequently queried columns based on analytics usage patterns:
  - inserted_at for date range filtering
  - session_id for grouping operations
  - status_code for filtering and grouping
  - device_type for analytics aggregations
  - method for request type filtering
  - path for popular pages analysis

  Automatically detects database type and adjusts queries accordingly:
  - PostgreSQL/SQLite: Uses IF NOT EXISTS clause
  - MySQL: Omits IF NOT EXISTS, adds length limit to path index

  Note: Uses regular CREATE INDEX (not CONCURRENTLY) to work within migration transactions.
  For production environments with large tables, consider running PostgreSQL indexes manually with CONCURRENTLY.
  """
  def add_indexes do
    repo = PhoenixAnalytics.Config.get_repo()
    database_type = PhoenixAnalytics.Services.Utility.database_type()

    {if_not_exists, path_column} =
      case database_type do
        :mysql -> {"", "path(255)"}
        _ -> {"IF NOT EXISTS ", "path"}
      end

    indexes = [
      "CREATE INDEX #{if_not_exists}idx_requests_inserted_at ON requests (inserted_at);",
      "CREATE INDEX #{if_not_exists}idx_requests_session_id ON requests (session_id);",
      "CREATE INDEX #{if_not_exists}idx_requests_status_code ON requests (status_code);",
      "CREATE INDEX #{if_not_exists}idx_requests_device_type ON requests (device_type);",
      "CREATE INDEX #{if_not_exists}idx_requests_method ON requests (method);",
      "CREATE INDEX #{if_not_exists}idx_requests_path ON requests (#{path_column});",
      "CREATE INDEX #{if_not_exists}idx_requests_date_status ON requests (inserted_at, status_code);",
      "CREATE INDEX #{if_not_exists}idx_requests_date_method ON requests (inserted_at, method);"
    ]

    results =
      Enum.map(indexes, fn index_query ->
        case repo.query(index_query) do
          {:ok, _result} -> {:ok, index_query}
          {:error, reason} -> {:error, {index_query, reason}}
        end
      end)

    successful = Enum.count(results, &match?({:ok, _}, &1))
    failed = Enum.count(results, &match?({:error, _}, &1))

    database_name = database_type |> Atom.to_string() |> String.capitalize()
    IO.puts("#{database_name} indexes applied: #{successful} successful, #{failed} failed")

    if failed > 0 do
      failed_queries = Enum.filter(results, &match?({:error, _}, &1))

      Enum.each(failed_queries, fn {:error, {query, reason}} ->
        reason_str =
          case reason do
            %{message: msg} when is_binary(msg) -> msg
            %{postgres: %{message: msg}} when is_binary(msg) -> msg
            %{mysql: %{message: msg}} when is_binary(msg) -> msg
            _ -> inspect(reason)
          end

        IO.puts("Failed index: #{String.slice(query, 0, 80)}... - #{reason_str}")
      end)
    end

    {:ok, "#{database_name} indexes processed: #{successful}/#{length(indexes)} successful"}
  end
end
