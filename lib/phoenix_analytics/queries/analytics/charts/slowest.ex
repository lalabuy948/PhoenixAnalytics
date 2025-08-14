defmodule PhoenixAnalytics.Queries.Analytics.Charts.Slowest do
  @moduledoc """
  Ecto-based queries for slowest pages and resources.

  This module provides functions to generate Ecto queries for
  analyzing response time performance.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers

  @doc """
  Gets slowest pages for a given date range.
  """
  def slowest_pages(from_date, to_date) do
    RequestLog
    |> Helpers.filter_successful()
    |> Helpers.exclude_non_page()
    |> Helpers.exclude_dev()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.path)
    |> select([r], %{
      path: r.path,
      duration: fragment("CAST(ROUND(AVG(?), 2) AS FLOAT)", r.duration_ms)
    })
    |> order_by([r], desc: fragment("CAST(AVG(?) AS FLOAT)", r.duration_ms))
    |> limit(6)
  end

  @doc """
  Gets slowest resources (non-page requests) for a given date range.
  """
  def slowest_resources(from_date, to_date) do
    RequestLog
    |> where([r], r.status_code == 200)
    |> where(
      [r],
      not like(r.path, "%/%") or
        like(r.path, "%.js%") or
        like(r.path, "%.css%") or
        like(r.path, "%.png%") or
        like(r.path, "%.jpg%") or
        like(r.path, "%.svg%") or
        like(r.path, "%.gif%") or
        like(r.path, "%.woff%") or
        like(r.path, "%.ico%")
    )
    |> Helpers.exclude_dev()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.path)
    |> select([r], %{
      path: r.path,
      duration: fragment("CAST(ROUND(AVG(?), 2) AS FLOAT)", r.duration_ms)
    })
    |> order_by([r], desc: fragment("CAST(AVG(?) AS FLOAT)", r.duration_ms))
    |> limit(6)
  end
end
