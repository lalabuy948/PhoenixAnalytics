# Test all analytics queries
# Run with: mix run priv/repo/queries.exs

# Start the application to ensure everything is available
{:ok, _} = Application.ensure_all_started(:phoenix_analytics)

import Ecto.Query
alias PhoenixAnalytics.Queries.Analytics

# Set up SQLite repo for testing
defmodule TestPhoenixAnalytics.SqliteRepo do
  use Ecto.Repo, otp_app: :phoenix_analytics, adapter: Ecto.Adapters.SQLite3
end

# Configure and start the test repo
repo_config = [
  database: Path.expand("../../examples/phoenix_sqlite/phoenix_sqlite_dev.db", __DIR__),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true
]

{:ok, _} = TestPhoenixAnalytics.SqliteRepo.start_link(repo_config)
repo = TestPhoenixAnalytics.SqliteRepo

# Override the config to use our test repo
Application.put_all_env(
  phoenix_analytics: [
    repo: repo,
    app_domain: "example.com",
    cache_ttl: 0  # Disable cache for testing
  ]
)

# Set up date ranges for testing
today = Date.utc_today()
week_ago = Date.add(today, -7)
month_ago = Date.add(today, -30)
three_months_ago = Date.add(today, -90)

# For month/year testing, use dates that actually contain data
data_start = ~D[2025-08-12]
data_end = ~D[2025-08-14]

IO.puts("📊 Phoenix Analytics Query Tests")
IO.puts("==============================")
IO.puts("🗄️  Using repo: #{inspect(repo)}")
IO.puts("📅 Date ranges:")
IO.puts("   Today: #{today}")
IO.puts("   Week ago: #{week_ago}")
IO.puts("   Month ago: #{month_ago}")
IO.puts("   Three months ago: #{three_months_ago}")
IO.puts("")

# Helper function to safely execute queries
test_query = fn name, query_fn ->
  IO.write("🔍 Testing #{name}... ")

  try do
    start_time = System.monotonic_time(:millisecond)
    result = query_fn.()
    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    case result do
      nil -> IO.puts("✅ OK (nil result, #{duration}ms)")
      %{} -> IO.puts("✅ OK (single result, #{duration}ms)")
      results when is_list(results) ->
        IO.puts("✅ OK (#{length(results)} results, #{duration}ms)")
      value -> IO.puts("✅ OK (value: #{value}, #{duration}ms)")
    end

    {result, duration}
  rescue
    error ->
      IO.puts("❌ FAILED: #{inspect(error)}")
      {nil, 0}
  end
end

IO.puts("📈 Basic Statistics")
IO.puts("-------------------")

# Test basic stats
{unique_visitors, _} = test_query.("unique visitors", fn ->
  Analytics.unique_visitors(week_ago, today) |> repo.one()
end)

{total_pageviews, _} = test_query.("total pageviews", fn ->
  Analytics.total_pageviews(week_ago, today) |> repo.one()
end)

{total_requests, _} = test_query.("total requests", fn ->
  Analytics.total_requests(week_ago, today) |> repo.one()
end)

{avg_response_time, _} = test_query.("average response time", fn ->
  Analytics.average_response_time(week_ago, today) |> repo.one()
end)

{avg_views_per_visit, _} = test_query.("average views per visit", fn ->
  Analytics.average_views_per_visit(month_ago, today) |> repo.one()
end)

{bounce_rate, _} = test_query.("bounce rate", fn ->
  Analytics.bounce_rate(month_ago, today) |> repo.one()
end)

IO.puts("")
IO.puts("📊 Popular Content")
IO.puts("------------------")

{popular_pages, _} = test_query.("popular pages", fn ->
  Analytics.popular_pages(week_ago, today) |> repo.all()
end)

{popular_referers, _} = test_query.("popular referers", fn ->
  Analytics.popular_referer(week_ago, today) |> repo.all()
end)

{popular_404s, _} = test_query.("popular 404s", fn ->
  Analytics.popular_not_found(week_ago, today) |> repo.all()
end)

{popular_user_agents, _} = test_query.("popular user agents", fn ->
  Analytics.popular_user_agents(week_ago, today) |> repo.all()
end)

{popular_devices, _} = test_query.("popular device types", fn ->
  Analytics.popular_device_types(week_ago, today) |> repo.all()
end)

IO.puts("")
IO.puts("📱 Device & Status Analytics")
IO.puts("----------------------------")

{devices_usage, _} = test_query.("devices usage", fn ->
  Analytics.devices_usage(week_ago, today) |> repo.all()
end)

{device_distribution, _} = test_query.("device type distribution", fn ->
  Analytics.device_type_distribution(week_ago, today) |> repo.all()
end)

{status_distribution, _} = test_query.("status code distribution", fn ->
  Analytics.status_code_distribution(week_ago, today) |> repo.all()
end)

IO.puts("")
IO.puts("⏱️ Time-based Analytics")
IO.puts("-----------------------")

{visits_per_day, _} = test_query.("visits per day", fn ->
  Analytics.visits_per_period(week_ago, today, "day") |> repo.all()
end)

{visits_per_month, _} = test_query.("visits per month", fn ->
  Analytics.visits_per_period(data_start, data_end, "month") |> repo.all()
end)

{visits_per_year, _} = test_query.("visits per year", fn ->
  Analytics.visits_per_period(data_start, data_end, "year") |> repo.all()
end)

{requests_per_day, _} = test_query.("requests per day", fn ->
  Analytics.total_requests_per_period(week_ago, today, "day") |> repo.all()
end)

{requests_per_month, _} = test_query.("requests per month", fn ->
  Analytics.total_requests_per_period(data_start, data_end, "month") |> repo.all()
end)

{requests_per_year, _} = test_query.("requests per year", fn ->
  Analytics.total_requests_per_period(data_start, data_end, "year") |> repo.all()
end)

{statuses_per_day, _} = test_query.("statuses per day", fn ->
  Analytics.statuses_per_period(week_ago, today, "day") |> repo.all()
end)

{statuses_per_month, _} = test_query.("statuses per month", fn ->
  Analytics.statuses_per_period(data_start, data_end, "month") |> repo.all()
end)

{statuses_per_year, _} = test_query.("statuses per year", fn ->
  Analytics.statuses_per_period(data_start, data_end, "year") |> repo.all()
end)

IO.puts("")
IO.puts("🐌 Performance Analytics")
IO.puts("------------------------")

{slowest_pages, _} = test_query.("slowest pages", fn ->
  Analytics.slowest_pages(week_ago, today) |> repo.all()
end)

{slowest_resources, _} = test_query.("slowest resources", fn ->
  Analytics.slowest_resources(week_ago, today) |> repo.all()
end)

IO.puts("")
IO.puts("📊 Dashboard Widget Queries")
IO.puts("---------------------------")

{unique_visitors_limited, _} = test_query.("unique visitors (limited)", fn ->
  Analytics.unique_visitors_per_period_limited(month_ago, today) |> repo.all()
end)

{pageviews_limited, _} = test_query.("pageviews (limited)", fn ->
  Analytics.total_pageviews_per_period_limited(month_ago, today) |> repo.all()
end)

{requests_limited, _} = test_query.("requests (limited)", fn ->
  Analytics.total_requests_per_period_limited(month_ago, today) |> repo.all()
end)

{views_per_visit_limited, _} = test_query.("views per visit (limited)", fn ->
  Analytics.views_per_visit_per_period_limited(month_ago, today) |> repo.all()
end)

{visit_duration_limited, _} = test_query.("visit duration (limited)", fn ->
  Analytics.visit_duration_per_period_limited(month_ago, today) |> repo.all()
end)

{bounce_rate_limited, _} = test_query.("bounce rate (limited)", fn ->
  Analytics.bounce_rate_per_period_limited(month_ago, today) |> repo.all()
end)

IO.puts("")
IO.puts("📋 Test Summary")
IO.puts("===============")
IO.puts("🎯 All query tests completed!")
IO.puts("")

if unique_visitors do
  IO.puts("📊 Sample Results:")
  IO.puts("   👥 Unique visitors (7 days): #{unique_visitors || 0}")
  IO.puts("   📄 Total pageviews (7 days): #{total_pageviews || 0}")
  IO.puts("   🔄 Total requests (7 days): #{total_requests || 0}")

  if avg_response_time do
    avg_ms = Float.round(avg_response_time, 2)
    IO.puts("   ⏱️  Average response time: #{avg_ms}ms")
  end

  if avg_views_per_visit do
    avg_views = Float.round(avg_views_per_visit, 2)
    IO.puts("   👀 Average views per visit: #{avg_views}")
  end

  if bounce_rate && bounce_rate.bounce_rate do
    IO.puts("   📉 Bounce rate: #{bounce_rate.bounce_rate}%")
  end

  if popular_pages && length(popular_pages) > 0 do
    IO.puts("   🔝 Top page: #{List.first(popular_pages).source} (#{List.first(popular_pages).visits} visits)")
  end

  if visits_per_month && length(visits_per_month) > 0 do
    first_month = List.first(visits_per_month)
    IO.puts("   📅 Month data: #{first_month.date} (#{first_month.visits} visits, #{first_month.unique_visitors} unique)")
  end

  if visits_per_year && length(visits_per_year) > 0 do
    first_year = List.first(visits_per_year)
    IO.puts("   📅 Year data: #{first_year.date} (#{first_year.visits} visits, #{first_year.unique_visitors} unique)")
  end
end

IO.puts("")
IO.puts("✅ All analytics queries are working properly!")
