# Seed analytics records with dynamic repo selection
# Run with: mix run priv/repo/seeds.exs [postgres|mysql|sqlite]

Code.require_file("./priv/repo/seed_data.exs")

# Start the application to ensure everything is available
{:ok, _} = Application.ensure_all_started(:phoenix_analytics)

# Get the user's configured repo from command line args
arg = System.argv()
{repo_module, repo_config} = case List.first(arg) do
  "postgres" ->
    {PhoenixAnalyticsDev.PostgresRepo, [
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "phoenix_postgres_dev",
      stacktrace: true,
      show_sensitive_data_on_connection_error: true,
      pool_size: 10
    ]}
  "mysql" ->
    {PhoenixAnalyticsDev.MysqlRepo, [
      username: "root",
      password: "",
      hostname: "localhost",
      database: "phoenix_mysql_dev",
      stacktrace: true,
      show_sensitive_data_on_connection_error: true,
      pool_size: 10
    ]}
  _ ->
    {PhoenixAnalyticsDev.SqliteRepo, [
      database: Path.expand("../../examples/phoenix_sqlite/phoenix_sqlite_dev.db", __DIR__),
      pool_size: 5,
      stacktrace: true,
      show_sensitive_data_on_connection_error: true
    ]}
end

# Define repo modules locally for seeding with proper configuration
defmodule PhoenixAnalyticsDev.PostgresRepo do
  use Ecto.Repo, otp_app: :phoenix_analytics, adapter: Ecto.Adapters.Postgres
end

defmodule PhoenixAnalyticsDev.MysqlRepo do
  use Ecto.Repo, otp_app: :phoenix_analytics, adapter: Ecto.Adapters.MyXQL
end

defmodule PhoenixAnalyticsDev.SqliteRepo do
  use Ecto.Repo, otp_app: :phoenix_analytics, adapter: Ecto.Adapters.SQLite3
end

# Configure the application environment with the selected repo
Application.put_all_env(
  phoenix_analytics: [
    repo: repo_module,
    app_domain: "example.com",
    cache_ttl: 60
  ]
)

# Start the repo with the proper configuration
{:ok, _} = repo_module.start_link(repo_config)


alias PhoenixAnalytics.Entities.RequestLog

# Run the migration to create tables
PhoenixAnalytics.Migration.up()

batch_size = 5
total_records = case Enum.at(arg, 1) do
  nil -> 1_000_000
  count_str -> String.to_integer(count_str)
end

# Current year date range - used in seed_data.exs for date generation
_current_year = Date.utc_today().year

start_time = System.monotonic_time(:millisecond)

1..total_records
|> Enum.chunk_every(batch_size)
|> Enum.with_index(1)
|> Enum.each(fn {batch, batch_num} ->
  batch_start = System.monotonic_time(:millisecond)

  prepared_data =
    Task.async_stream(batch, fn _ ->
      request_struct = SeedData.generate_request_data()
      request_data = Map.from_struct(request_struct)

      request_data
    end, max_concurrency: System.schedulers_online() * 2)
    |> Enum.map(fn {:ok, result} -> result end)

  # Convert to changesets for validation, then back to maps
  data_for_insert = Enum.map(prepared_data, fn request_data ->
    changeset = RequestLog.changeset(%RequestLog{}, request_data)
    if changeset.valid? do
      # Convert the changeset back to a map for insert_all
      Ecto.Changeset.apply_changes(changeset) |> Map.from_struct() |> Map.drop([:__meta__])
    else
      # If invalid, just use the original data
      request_data
    end
  end)

  # Insert batch using the configured repo
  try do
    {count, _} = repo_module.insert_all(
      RequestLog,
      data_for_insert,
      returning: false
    )

    batch_time = System.monotonic_time(:millisecond) - batch_start
    total_inserted = batch_num * batch_size
    progress = Float.round(total_inserted / total_records * 100, 1)

    IO.puts("✅ Batch #{batch_num}: #{count} records (#{progress}% - #{batch_time}ms)")
  rescue
    error ->
      IO.puts("❌ Error inserting batch #{batch_num}: #{inspect(error)}")
      IO.puts("   Error details: #{Exception.message(error)}")
      # Debug: show first record that failed
      if length(data_for_insert) > 0 do
        first_record = List.first(data_for_insert)
        IO.puts("   📝 First record that failed: #{inspect(first_record, pretty: true, limit: 3)}")
      end
  end
end)

total_time = System.monotonic_time(:millisecond) - start_time
records_per_second = round(total_records / (total_time / 1000))

IO.puts("")
IO.puts("🎉 Seeding completed!")
IO.puts("⏱️  Total time: #{Float.round(total_time / 1000, 2)} seconds")
IO.puts("🚀 Speed: #{records_per_second} records/second")

# Verify the data
final_count = repo_module.aggregate(RequestLog, :count, :request_id)
IO.puts("📊 Final record count: #{final_count}")
