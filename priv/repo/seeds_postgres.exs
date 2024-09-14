# Example seed data

Code.require_file("./priv/repo/seed_data.exs")

{:ok, db} = Duckdbex.open()
{:ok, conn} = Duckdbex.connection(db)

Duckdbex.query(conn, "INSTALL postgres;")
Duckdbex.query(conn, "LOAD postgres;")

Duckdbex.query(
  conn,
  "ATTACH 'dbname=postgres user=phoenix password=analytics host=localhost' AS postgres_db (TYPE POSTGRES);"
)
|> IO.inspect()

query = """
CREATE TABLE IF NOT EXISTS postgres_db.requests (
  request_id UUID PRIMARY KEY,
  method VARCHAR NOT NULL,
  path VARCHAR NOT NULL,
  status_code SMALLINT NOT NULL,
  duration_ms INTEGER NOT NULL,
  user_agent VARCHAR,
  remote_ip VARCHAR,
  referer VARCHAR,
  device VARCHAR,
  session_id UUID,
  session_page_views INTEGER,
  inserted_at TIMESTAMP
);
"""

Duckdbex.query(conn, query) |> IO.inspect()

batch_size = 1_000

1..1_000_000
|> Enum.chunk_every(batch_size)
|> Enum.with_index(1)
|> Enum.each(fn {data, index} ->
  batch =
    Task.async_stream(data, fn _ ->
      SeedData.generate_request_data()
    end)
    |> Enum.map(fn {:ok, result} -> result end)

  columns =
    ~w(request_id method path status_code duration_ms user_agent remote_ip referer device session_id session_page_views inserted_at)

  placeholders = List.duplicate("?", length(columns)) |> Enum.join(", ")
  batch_size = length(batch)
  values_placeholders = List.duplicate("(#{placeholders})", batch_size) |> Enum.join(", ")

  query =
    "INSERT INTO postgres_db.requests (#{Enum.join(columns, ", ")}) VALUES #{values_placeholders};"

  params =
    Enum.flat_map(
      batch,
      fn request_data ->
        [
          request_data.request_id,
          request_data.method,
          request_data.path,
          request_data.status_code,
          request_data.duration_ms,
          request_data.user_agent,
          request_data.remote_ip,
          request_data.referer,
          request_data.device_type,
          request_data.session_id,
          request_data.session_page_views,
          request_data.inserted_at
        ]
      end
    )

  {:ok, stmt_ref} = Duckdbex.prepare_statement(conn, query)
  {:ok, _result_ref} = Duckdbex.execute_statement(stmt_ref, params)

  IO.inspect(label: "Chunk #{index} - Number of Records: #{index * batch_size}")
end)
