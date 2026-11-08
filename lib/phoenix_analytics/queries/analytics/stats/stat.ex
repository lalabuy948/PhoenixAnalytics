defmodule PhoenixAnalytics.Queries.Analytics.Stats.Stat do
  @moduledoc """
  Ecto-based statistics queries for PhoenixAnalytics.

  This module provides functions to generate Ecto queries for
  calculating various analytics statistics.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers

  @valid_intervals ~w(day month year)

  @doc """
  Gets unique visitors count for a given date range.
  """
  def unique_visitors(from_date, to_date) do
    RequestLog
    |> Helpers.exclude_bots()
    |> Helpers.filter_by_date(from_date, to_date)
    |> select([r], count(r.remote_ip, :distinct))
  end

  @doc """
  Gets total pageviews count for a given date range.
  """
  def total_pageviews(from_date, to_date) do
    RequestLog
    |> Helpers.page_views()
    |> Helpers.filter_by_date(from_date, to_date)
    |> select([r], count(r.request_id))
  end

  @doc """
  Gets total requests count for a given date range.
  """
  def total_requests(from_date, to_date) do
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> select([r], count(r.request_id))
  end

  @doc """
  Gets average views per visit for a given date range.
  """
  def average_views_per_visit(from_date, to_date) do
    session_views =
      RequestLog
      |> Helpers.exclude_bots()
      |> Helpers.filter_by_date(from_date, to_date)
      |> group_by([r], r.session_id)
      |> Helpers.visit_sessions()
      |> select([r], %{page_views: max(r.session_page_views)})

    from(sv in subquery(session_views),
      select: fragment("CAST(AVG(?) AS FLOAT(53))", sv.page_views)
    )
  end

  @doc """
  Gets average visit duration for a given date range and interval.
  """
  def average_visit_duration(from_date, to_date, interval \\ "day")
      when interval in @valid_intervals do
    # This is a complex query that calculates session duration
    # Check database type for compatibility
    database_type = PhoenixAnalytics.Services.Utility.database_type()

    session_durations =
      case database_type do
        :sqlite ->
          # SQLite version using julianday function
          RequestLog
          |> Helpers.exclude_bots()
          |> Helpers.filter_by_date(from_date, to_date)
          |> group_by([r], r.session_id)
          |> Helpers.visit_sessions()
          |> select([r], %{
            session_id: r.session_id,
            duration:
              fragment(
                "(julianday(MAX(?)) - julianday(MIN(?))) * 24 * 60 * 60 * 1000",
                r.inserted_at,
                r.inserted_at
              )
          })

        :mysql ->
          # MySQL version using TIMESTAMPDIFF
          RequestLog
          |> Helpers.exclude_bots()
          |> Helpers.filter_by_date(from_date, to_date)
          |> group_by([r], r.session_id)
          |> Helpers.visit_sessions()
          |> select([r], %{
            session_id: r.session_id,
            duration:
              fragment(
                "TIMESTAMPDIFF(MICROSECOND, MIN(?), MAX(?)) / 1000",
                r.inserted_at,
                r.inserted_at
              )
          })

        _ ->
          # PostgreSQL version using EXTRACT
          RequestLog
          |> Helpers.exclude_bots()
          |> Helpers.filter_by_date(from_date, to_date)
          |> group_by([r], r.session_id)
          |> Helpers.visit_sessions()
          |> select([r], %{
            session_id: r.session_id,
            duration:
              fragment(
                "CAST(EXTRACT(EPOCH FROM (MAX(?) - MIN(?))) * 1000 AS NUMERIC)",
                r.inserted_at,
                r.inserted_at
              )
          })
      end

    from(sd in subquery(session_durations),
      select: fragment("CAST(AVG(?) AS FLOAT(53))", sd.duration)
    )
  end

  @doc """
  Gets bounce rate for a given date range.
  """
  def bounce_rate(from_date, to_date) do
    # Calculate bounce rate: sessions with only 1 page view
    session_stats =
      RequestLog
      |> Helpers.exclude_bots()
      |> Helpers.filter_by_date(from_date, to_date)
      |> group_by([r], r.session_id)
      |> Helpers.visit_sessions()
      |> select([r], %{
        session_id: r.session_id,
        page_views: max(r.session_page_views)
      })

    from(ss in subquery(session_stats),
      select: %{
        bounce_rate:
          fragment(
            "CAST(ROUND(100.0 * SUM(CASE WHEN ? = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS FLOAT(53))",
            ss.page_views
          )
      }
    )
  end

  @doc """
  Gets the percentage of 5xx responses over all requests
  (assets and API calls included, same denominator as `total_requests`) for a given date range.
  """
  def error_rate(from_date, to_date) do
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> select(
      [r],
      fragment(
        "CAST(ROUND(100.0 * SUM(CASE WHEN ? >= 500 THEN 1 ELSE 0 END) / COUNT(*), 2) AS FLOAT(53))",
        r.status_code
      )
    )
  end

  @doc """
  Gets the `pct`-th percentile (nearest-rank) response time in ms for a given date range.

  Uses window functions only (no `percentile_cont`), so it runs on Postgres,
  SQLite 3.25+ and MySQL 8.
  """
  def response_time_percentile(from_date, to_date, pct) when pct in 1..100 do
    # Collapse to distinct durations first so the window sort runs over a few
    # thousand values instead of every row in the range
    histogram =
      from(r in Helpers.filter_by_date(RequestLog, from_date, to_date),
        group_by: r.duration_ms,
        windows: [ordered: [order_by: r.duration_ms], all: []],
        select: %{
          duration: r.duration_ms,
          cumulative: over(sum(count(r.request_id)), :ordered),
          total: over(sum(count(r.request_id)), :all)
        }
      )

    # Nearest rank: smallest value whose cumulative count >= pct% of total, compared without division
    from(h in subquery(histogram),
      where: h.cumulative * 100 >= h.total * ^pct,
      select: min(h.duration)
    )
  end

  @doc """
  Splits visitors active in the date range into "new" (first ever request falls
  in the range) and "returning" (seen before the range started).

  Visitors are hashed IPs, like `unique_visitors/2`, so this is approximate:
  NAT, mobile and rotating IPs blur the split. Looks back over all stored
  history up to `to_date`, so cost grows with table size, not range size.
  """
  def visitor_types(from_date, to_date) when not is_nil(from_date) and not is_nil(to_date) do
    range_start = Helpers.start_of(from_date)

    visitors =
      from(r in Helpers.exclude_bots(RequestLog),
        where: not is_nil(r.remote_ip) and r.inserted_at <= ^Helpers.end_of(to_date),
        group_by: r.remote_ip,
        having: max(r.inserted_at) >= ^range_start,
        select: %{
          type:
            fragment(
              "CASE WHEN MIN(?) < ? THEN 'returning' ELSE 'new' END",
              r.inserted_at,
              ^range_start
            )
        }
      )

    from(v in subquery(visitors),
      group_by: v.type,
      select: %{type: v.type, count: count()},
      order_by: v.type
    )
  end

  @doc """
  Gets average response time for a given date range.
  """
  def average_response_time(from_date, to_date) do
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> select([r], fragment("CAST(AVG(?) AS FLOAT(53))", r.duration_ms))
  end

  @doc """
  Gets status code distribution for a given date range.
  """
  def status_code_distribution(from_date, to_date) do
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.status_code)
    |> select([r], %{
      status_code: r.status_code,
      count: count(r.request_id)
    })
    |> order_by([r], r.status_code)
  end

  @doc """
  Gets device type distribution for a given date range.
  """
  def device_type_distribution(from_date, to_date) do
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.device_type)
    |> select([r], %{
      device_type: r.device_type,
      count: count(r.request_id)
    })
    |> order_by([r], desc: count(r.request_id))
  end
end
