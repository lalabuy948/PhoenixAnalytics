alias PhoenixAnalytics.Queries.Analytics

{:ok, db} = Duckdbex.open("analytics.duckdb")
{:ok, conn} = Duckdbex.connection(db)

today = Date.utc_today()
three_months_ago = today |> Date.add(-3 * 30) |> Date.beginning_of_month()

default_to = today |> Date.to_string() |> Kernel.<>(" 23:59:59")
default_from = three_months_ago |> Date.to_string() |> Kernel.<>(" 00:00:00")

# --- total users ---

today = Date.utc_today()
week_ago = Date.utc_today() |> Date.add(-7)

{:ok, result_ref} = Duckdbex.query(conn, Analytics.unique_visitors(week_ago, today))
[[result | _] | _] = Duckdbex.fetch_all(result_ref)

IO.inspect("Total users: #{result}")

# --- slowest pages ---

query = Analytics.slowest_pages(Date.utc_today() |> Date.add(-7), Date.utc_today())

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

for [%{"path" => path, "duration" => duration}] <- result do
  IO.inspect("Page: #{path} Speed: #{duration}")
end

# --- slowest resources ---

query = Analytics.slowest_resources(Date.utc_today() |> Date.add(-7), Date.utc_today())

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

for [%{"path" => path, "duration" => duration}] <- result do
  IO.inspect("Resource: #{path} Speed: #{duration}")
end

# --- visits per day ---

query =
  Analytics.visits_per_period(Date.utc_today() |> Date.add(-180), Date.utc_today(), "day")

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

for [date | [visits | _]] <- result do
  IO.puts("Date: #{date} Visits: #{visits}")
end

# --- devices usage ---

query = Analytics.devices_usage(Date.utc_today() |> Date.add(-180), Date.utc_today())

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

for [device, visits | _] <- result do
  IO.puts("Device: #{device} Visits: #{visits}")
end

# --- http statuses ---

query =
  Analytics.statuses_per_period(Date.utc_today() |> Date.add(-30), Date.utc_today(), "day")

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

IO.inspect(result)

for [date | [{_, oks}, {_, redirects}, {_, errors}, {_, fails} | _]] <- result do
  IO.puts("Date: #{date} Oks: #{oks} Redirs: #{redirects} Errs: #{errors} Fails: #{fails}")
end

# --- total_requests_per_period ---

query = Analytics.total_requests_per_period(Date.utc_today() |> Date.add(-30), Date.utc_today())

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

for [date, hits] <- result do
  IO.inspect("date: #{date} | hits: #{hits}")
end

# --- views per visit ---

query =
  Analytics.views_per_visit_per_period_limited(
    Date.utc_today() |> Date.add(-30),
    Date.utc_today()
  )

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

IO.inspect("--- views per visit ---")

for [date, hits | _] <- result do
  IO.inspect("date: #{date} | hits: #{hits}")
end

# --- average views per visit ---

query =
  Analytics.average_views_per_visit(Date.utc_today() |> Date.add(-30), Date.utc_today())

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

IO.inspect("--- average views per visit ---")
IO.inspect(result)

# --- visit duration per period ---

query =
  Analytics.visit_duration_per_period_limited(
    Date.utc_today() |> Date.add(-30),
    Date.utc_today() |> Date.add(1)
  )

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

IO.inspect("--- visit duration per period ---")

for [date, hits | _] <- result do
  IO.inspect("date: #{date} | hits: #{hits}")
end

# --- avg visit duration ---

query =
  Analytics.average_visit_duration(Date.utc_today() |> Date.add(-30), Date.utc_today())

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

IO.inspect("--- avg visit duration ---")
IO.inspect(result)

# --- bounce rate ---

query = Analytics.bounce_rate(Date.utc_today() |> Date.add(-30), Date.utc_today())

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

IO.inspect(" --- bounce rate ---")
IO.inspect(result)

# --- bounce rate per period ---

query = Analytics.bounce_rate_per_period_limited(default_from, default_to)

{:ok, result_ref} = Duckdbex.query(conn, query)
result = Duckdbex.fetch_all(result_ref)

IO.inspect("--- bounce rate per period ---")
IO.inspect(result)
