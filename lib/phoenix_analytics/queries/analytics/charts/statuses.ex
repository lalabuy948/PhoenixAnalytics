defmodule PhoenixAnalytics.Queries.Analytics.Charts.Statuses do
  @moduledoc """
  Ecto-based queries for HTTP status code analytics per period.

  This module provides functions to generate Ecto queries for
  analyzing HTTP status code patterns over time periods.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers

  @valid_intervals ~w(hour day month year)

  @doc """
  Gets status code distribution per period for a given date range and interval.
  """
  def statuses_per_period(from_date, to_date, interval \\ "day")
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
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("strftime('%Y-%m-%d %H:00:00', ?)", r.inserted_at))

      "day" ->
        query
        |> group_by([r], fragment("DATE(?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE(?)", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("DATE(?)", r.inserted_at))

      "month" ->
        query
        |> group_by([r], fragment("strftime('%Y-%m', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("strftime('%Y-%m', ?)", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("strftime('%Y-%m', ?)", r.inserted_at))

      "year" ->
        query
        |> group_by([r], fragment("strftime('%Y', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("strftime('%Y', ?)", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
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
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("DATE_FORMAT(?, '%Y-%m-%d %H:00:00')", r.inserted_at))

      "day" ->
        query
        |> group_by([r], fragment("DATE(?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE(?)", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("DATE(?)", r.inserted_at))

      "month" ->
        query
        |> group_by([r], fragment("DATE_FORMAT(?, '%Y-%m')", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_FORMAT(?, '%Y-%m')", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("DATE_FORMAT(?, '%Y-%m')", r.inserted_at))

      "year" ->
        query
        |> group_by([r], fragment("DATE_FORMAT(?, '%Y')", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_FORMAT(?, '%Y')", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
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
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("DATE_TRUNC('hour', ?)", r.inserted_at))

      "day" ->
        query
        |> group_by([r], fragment("DATE(?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE(?)", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("DATE(?)", r.inserted_at))

      "month" ->
        query
        |> group_by([r], fragment("DATE_TRUNC('month', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_TRUNC('month', ?)", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("DATE_TRUNC('month', ?)", r.inserted_at))

      "year" ->
        query
        |> group_by([r], fragment("DATE_TRUNC('year', ?)", r.inserted_at))
        |> select([r], %{
          date: fragment("DATE_TRUNC('year', ?)", r.inserted_at),
          ok_200s:
            fragment("SUM(CASE WHEN ? BETWEEN 200 AND 299 THEN 1 ELSE 0 END)", r.status_code),
          redirects_300s:
            fragment("SUM(CASE WHEN ? BETWEEN 300 AND 399 THEN 1 ELSE 0 END)", r.status_code),
          errors_400s:
            fragment("SUM(CASE WHEN ? BETWEEN 400 AND 499 THEN 1 ELSE 0 END)", r.status_code),
          fails_500s:
            fragment("SUM(CASE WHEN ? BETWEEN 500 AND 599 THEN 1 ELSE 0 END)", r.status_code)
        })
        |> order_by([r], fragment("DATE_TRUNC('year', ?)", r.inserted_at))
    end
  end
end
