defmodule PhoenixAnalytics.Queries.Analytics.Stats.PerPeriod do
  @moduledoc """
  Ecto-based queries for period-based statistics.

  This module provides functions to generate Ecto queries for
  calculating analytics statistics over time periods.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers

  @valid_intervals ~w(day month year)

  @doc """
  Gets average views per visit per period for a given date range.
  """
  def views_per_visit_per_period_limited(from_date, to_date, interval \\ "day")
      when interval in @valid_intervals do
    # Calculate views per visit by session, then average by period
    session_stats =
      RequestLog
      |> Helpers.exclude_bots()
      |> Helpers.filter_by_date(from_date, to_date)
      |> group_by([r], [fragment("DATE(?)", r.inserted_at), r.session_id])
      |> Helpers.visit_sessions()
      |> select([r], %{
        period: fragment("DATE(?)", r.inserted_at),
        session_id: r.session_id,
        page_views: max(r.session_page_views)
      })

    from(ss in subquery(session_stats),
      group_by: ss.period,
      select: %{
        date: ss.period,
        hits: fragment("CAST(ROUND(AVG(?), 2) AS FLOAT(53))", ss.page_views)
      },
      order_by: ss.period
    )
  end

  @doc """
  Gets visit duration per period for a given date range.
  """
  def visit_duration_per_period_limited(from_date, to_date, interval \\ "day")
      when interval in @valid_intervals do
    # Calculate session duration by finding min/max timestamps per session
    # Check database type for compatibility
    database_type = PhoenixAnalytics.Services.Utility.database_type()

    session_durations =
      case database_type do
        :sqlite ->
          # SQLite version using julianday function
          RequestLog
          |> Helpers.exclude_bots()
          |> Helpers.filter_by_date(from_date, to_date)
          |> group_by([r], [fragment("DATE(?)", r.inserted_at), r.session_id])
          |> Helpers.visit_sessions()
          |> select([r], %{
            period: fragment("DATE(?)", r.inserted_at),
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
          |> group_by([r], [fragment("DATE(?)", r.inserted_at), r.session_id])
          |> Helpers.visit_sessions()
          |> select([r], %{
            period: fragment("DATE(?)", r.inserted_at),
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
          |> group_by([r], [fragment("DATE(?)", r.inserted_at), r.session_id])
          |> Helpers.visit_sessions()
          |> select([r], %{
            period: fragment("DATE(?)", r.inserted_at),
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
      group_by: sd.period,
      select: %{
        date: sd.period,
        hits: fragment("CAST(ROUND(AVG(?), 2) AS FLOAT(53))", sd.duration)
      },
      order_by: sd.period
    )
  end

  @doc """
  Gets bounce rate per period for a given date range.
  """
  def bounce_rate_per_period_limited(from_date, to_date, interval \\ "day")
      when interval in @valid_intervals do
    # Calculate bounce rate (sessions with only 1 page view) by period
    session_stats =
      RequestLog
      |> Helpers.exclude_bots()
      |> Helpers.filter_by_date(from_date, to_date)
      |> group_by([r], [fragment("DATE(?)", r.inserted_at), r.session_id])
      |> Helpers.visit_sessions()
      |> select([r], %{
        period: fragment("DATE(?)", r.inserted_at),
        session_id: r.session_id,
        page_views: max(r.session_page_views)
      })

    from(ss in subquery(session_stats),
      group_by: ss.period,
      select: %{
        date: ss.period,
        hits:
          fragment(
            "CAST(ROUND(100.0 * SUM(CASE WHEN ? = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS FLOAT(53))",
            ss.page_views
          )
      },
      order_by: ss.period
    )
  end

  @doc """
  Gets unique visitors per period for a given date range.
  """
  def unique_visitors_per_period_limited(from_date, to_date, interval \\ "day")
      when interval in @valid_intervals do
    RequestLog
    |> Helpers.exclude_bots()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], fragment("DATE(?)", r.inserted_at))
    |> select([r], %{
      date: fragment("DATE(?)", r.inserted_at),
      hits: count(r.remote_ip, :distinct)
    })
    |> order_by([r], fragment("DATE(?)", r.inserted_at))
  end

  @doc """
  Gets total pageviews per period for a given date range.
  """
  def total_pageviews_per_period_limited(from_date, to_date, interval \\ "day")
      when interval in @valid_intervals do
    RequestLog
    |> Helpers.page_views()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], fragment("DATE(?)", r.inserted_at))
    |> select([r], %{
      date: fragment("DATE(?)", r.inserted_at),
      hits: count(r.request_id)
    })
    |> order_by([r], fragment("DATE(?)", r.inserted_at))
  end
end
