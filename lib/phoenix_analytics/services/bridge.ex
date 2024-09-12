defmodule PhoenixAnalytics.Services.Bridge do
  alias PhoenixAnalytics.Queries
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
      Duckdbex.query(conn, "INSTALL postgres;")
      Duckdbex.query(conn, "LOAD postgres;")

      Duckdbex.query(conn, Queries.Table.attach_postgres()) |> IO.inspect()
    end
  end
end
