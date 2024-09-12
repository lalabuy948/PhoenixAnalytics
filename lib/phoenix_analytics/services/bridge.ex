defmodule PhoenixAnalytics.Services.Bridge do
  alias PhoenixAnalytics.Queries
  alias PhoenixAnalytics.Services.Utility

  def attach_postgres(conn) do
    if Utility.mode() == :duck_postgres do
      Duckdbex.query(conn, "INSTALL postgres;")
      Duckdbex.query(conn, "LOAD postgres;")

      Duckdbex.query(conn, Queries.Table.attach_postgres()) |> IO.inspect()
    end
  end
end
