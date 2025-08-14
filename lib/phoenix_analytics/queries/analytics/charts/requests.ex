defmodule PhoenixAnalytics.Queries.Analytics.Charts.Requests do
  @moduledoc """
  Ecto-based queries for request analytics per period.

  This module provides functions to generate Ecto queries for
  analyzing request patterns over time periods.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers

  @valid_intervals ~w(hour day month year)

  @doc """
  Gets total requests per period for a given date range and interval.
  """
  def total_requests_per_period(from_date, to_date, interval \\ "day")
      when interval in @valid_intervals do
    # Build query with database-specific logic
    database_type = PhoenixAnalytics.Services.Utility.database_type()

    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> apply_grouping_and_selection(database_type, interval)
  end

  # Helper function to apply database-specific grouping and selection
  defp apply_grouping_and_selection(query, :sqlite, interval) do
    case interval do
      "hour" ->
        query
        |> group_by([r], fragment("strftime('%Y-%m-%d %H:00:00', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("strftime('%Y-%m-%d %H:00:00', ?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("strftime('%Y-%m-%d %H:00:00', ?)", r.inserted_at))

      "day" ->
        query
        |> group_by([r], fragment("DATE(?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE(?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE(?)", r.inserted_at))

      "month" ->
        query
        |> group_by([r], fragment("strftime('%Y-%m', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("strftime('%Y-%m', ?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("strftime('%Y-%m', ?)", r.inserted_at))

      "year" ->
        query
        |> group_by([r], fragment("strftime('%Y', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("strftime('%Y', ?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("strftime('%Y', ?)", r.inserted_at))
    end
  end

  defp apply_grouping_and_selection(query, :mysql, interval) do
    # MySQL version using DATE_FORMAT
    case interval do
      "hour" ->
        query
        |> group_by([r], fragment("DATE_FORMAT(?, '%Y-%m-%d %H:00:00')", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_FORMAT(?, '%Y-%m-%d %H:00:00')", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE_FORMAT(?, '%Y-%m-%d %H:00:00')", r.inserted_at))

      "day" ->
        query
        |> group_by([r], fragment("DATE(?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE(?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE(?)", r.inserted_at))

      "month" ->
        query
        |> group_by([r], fragment("DATE_FORMAT(?, '%Y-%m')", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_FORMAT(?, '%Y-%m')", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE_FORMAT(?, '%Y-%m')", r.inserted_at))

      "year" ->
        query
        |> group_by([r], fragment("DATE_FORMAT(?, '%Y')", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_FORMAT(?, '%Y')", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE_FORMAT(?, '%Y')", r.inserted_at))
    end
  end

  defp apply_grouping_and_selection(query, _, interval) do
    # PostgreSQL version using DATE_TRUNC
    case interval do
      "hour" ->
        query
        |> group_by([r], fragment("DATE_TRUNC('hour', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_TRUNC('hour', ?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE_TRUNC('hour', ?)", r.inserted_at))

      "day" ->
        query
        |> group_by([r], fragment("DATE(?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE(?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE(?)", r.inserted_at))

      "month" ->
        query
        |> group_by([r], fragment("DATE_TRUNC('month', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_TRUNC('month', ?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE_TRUNC('month', ?)", r.inserted_at))

      "year" ->
        query
        |> group_by([r], fragment("DATE_TRUNC('year', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_TRUNC('year', ?)", r.inserted_at),
          hits: count(r.request_id)
        })
        |> order_by([r], fragment("DATE_TRUNC('year', ?)", r.inserted_at))
    end
  end

  @doc """
  Gets limited total requests per period for dashboard widgets.
  """
  def total_requests_per_period_limited(from_date, to_date) do
    total_requests_per_period(from_date, to_date, "day")
    |> limit(30)
  end
end
