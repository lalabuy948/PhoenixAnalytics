defmodule PhoenixAnalytics.Services.Bridge do
  alias PhoenixAnalytics.Services.Utility

  @doc """
  Attaches PostgreSQL to the DuckDB connection if the mode is set to :duck_postgres.

  This function performs the following steps:
  1. Installs the PostgreSQL extension
  2. Loads the PostgreSQL extension
  3. Executes the attach_postgres query

  ## Parameters

    - conn: The DuckDB connection

  ## Returns

    Returns the result of the attach_postgres query.

  """
  def attach_postgres(db, conn) do
    if Utility.mode() == :duck_postgres do
      Duckdbex.query(conn, "INSTALL postgres;")
      Duckdbex.query(conn, "LOAD postgres;")

      unless Duckdbex.extension_is_loaded(db, "postgres") do
        {:error, "duckdb: failed to load postgres extension"}
      end

      Duckdbex.query(conn, "SET pg_experimental_filter_pushdown=TRUE;")
      Duckdbex.query(conn, "SET pg_pages_per_task = 9876543;")
      Duckdbex.query(conn, "SET pg_use_ctid_scan=false;")

      postgres_conn = Application.fetch_env!(:phoenix_analytics, :postgres_conn)

      case Duckdbex.query(conn, "ATTACH '#{postgres_conn}' AS postgres_db (TYPE POSTGRES);") do
        {:ok, _} -> {:ok, "duckdb: postgres database connected"}
        {:error, error} -> raise "duckdb: postgres connection failed: #{inspect(error)}"
      end
    end
  end
end
