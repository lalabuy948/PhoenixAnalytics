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
    |> Helpers.filter_by_date(from_date, to_date)
    |> select([r], count(r.remote_ip, :distinct))
  end

  @doc """
  Gets total pageviews count for a given date range.
  """
  def total_pageviews(from_date, to_date) do
    RequestLog
    |> Helpers.filter_get_requests()
    |> Helpers.filter_successful()
    |> Helpers.exclude_non_page()
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
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> select([r], fragment("CAST(AVG(?) AS FLOAT)", r.session_page_views))
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
          |> Helpers.filter_by_date(from_date, to_date)
          |> group_by([r], r.session_id)
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
          |> Helpers.filter_by_date(from_date, to_date)
          |> group_by([r], r.session_id)
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
          |> Helpers.filter_by_date(from_date, to_date)
          |> group_by([r], r.session_id)
          |> select([r], %{
              session_id: r.session_id,
              duration:
                fragment(
                  "EXTRACT(EPOCH FROM (MAX(?) - MIN(?))) * 1000",
                  r.inserted_at,
                  r.inserted_at
                )
            })
      end

    from(sd in subquery(session_durations),
      select: fragment("CAST(AVG(?) AS FLOAT)", sd.duration)
    )
  end

  @doc """
  Gets bounce rate for a given date range.
  """
  def bounce_rate(from_date, to_date) do
    # Calculate bounce rate: sessions with only 1 page view
    session_stats =
      RequestLog
      |> Helpers.filter_by_date(from_date, to_date)
      |> group_by([r], r.session_id)
      |> select([r], %{
          session_id: r.session_id,
          page_views: max(r.session_page_views)
        })

    from(ss in subquery(session_stats),
      select: %{
        bounce_rate:
          fragment(
            "CAST(ROUND(100.0 * SUM(CASE WHEN ? = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS FLOAT)",
            ss.page_views
          )
      }
    )
  end

  @doc """
  Gets average response time for a given date range.
  """
  def average_response_time(from_date, to_date) do
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> select([r], fragment("CAST(AVG(?) AS FLOAT)", r.duration_ms))
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
