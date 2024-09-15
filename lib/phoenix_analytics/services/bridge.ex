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
  def attach_postgres(conn) do
    if Utility.mode() == :duck_postgres do
      Duckdbex.query(conn, "INSTALL postgres_scanner;") |> IO.inspect()
      Duckdbex.query(conn, "LOAD postgres_scanner;") |> IO.inspect()

      Duckdbex.query(conn, "SET pg_experimental_filter_pushdown=TRUE;") |> IO.inspect()
      Duckdbex.query(conn, "SET pg_pages_per_task = 9876543;") |> IO.inspect()
      Duckdbex.query(conn, "SET pg_use_ctid_scan=false;") |> IO.inspect()

      postgres_conn = Application.fetch_env!(:phoenix_analytics, :postgres_conn)

      Duckdbex.query(conn, "ATTACH '#{postgres_conn}' AS postgres_db (TYPE POSTGRES);")
      |> IO.inspect()
    end
  end
end
