# Example seed data

Code.require_file("./priv/repo/seed_data.exs")

PhoenixAnalytics.Migration.up()

db_path = System.get_env("DUCKDB_PATH") || "analytics.duckdb"
{:ok, db} = Duckdbex.open(db_path)
{:ok, conn} = Duckdbex.connection(db)
{:ok, appender} = Duckdbex.appender(conn, "requests")

batch_size = 1_000

1..1_000_000
|> Enum.chunk_every(batch_size)
|> Enum.with_index(1)
|> Enum.each(fn {data, index} ->
  prepared_data =
    Task.async_stream(data, fn _ ->
      SeedData.generate_request_data() |> SeedData.prepare_values()
    end)
    |> Enum.map(fn {:ok, result} -> result end)

  IO.inspect(label: "Chunk #{index} - Number of Records: #{index * batch_size}")

  Duckdbex.appender_add_rows(appender, prepared_data)
end)
