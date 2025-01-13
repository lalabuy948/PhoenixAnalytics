defmodule PhoenixAnalytics.Migration do
  @moduledoc false

  alias PhoenixAnalytics.Queries
  alias PhoenixAnalytics.Services.Bridge

  @db_path Application.compile_env(:phoenix_analytics, :duckdb_path) ||
             System.get_env("DUCKDB_PATH")
  @in_memory Application.compile_env(:phoenix_analytics, :in_memory) ||
               System.get_env("DUCKDB_IN_MEMORY")

  def up do
    {:ok, db} = open_duckdb()
    {:ok, conn} = Duckdbex.connection(db)

    Bridge.attach_postgres(db, conn)

    query = Queries.Table.create_requests()

    case Duckdbex.query(conn, query) do
      {:ok, result} ->
        IO.puts("Migration applied: requests table created")
        {:ok, result}

      {:error, reason} ->
        IO.puts("Failed to apply migration: #{reason}")
        {:error, reason}
    end
  end

  def down do
    {:ok, db} = open_duckdb()
    {:ok, conn} = Duckdbex.connection(db)

    Bridge.attach_postgres(db, conn)

    query = Queries.Table.drop_requests()

    case Duckdbex.query(conn, query) do
      {:ok, result} ->
        IO.puts("Migration rolled back: requests table dropped")
        {:ok, result}

      {:error, reason} ->
        IO.puts("Failed to roll back migration: #{reason}")
        {:error, reason}
    end
  end

  defp open_duckdb() do
    case @in_memory do
      true -> Duckdbex.open()
      _ -> Duckdbex.open(@db_path)
    end
  end
end
