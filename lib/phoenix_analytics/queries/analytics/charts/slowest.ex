defmodule PhoenixAnalytics.Queries.Analytics.Charts.Slowest do
  @moduledoc """
  Ecto-based queries for slowest endpoints and resources.

  This module provides functions to generate Ecto queries for
  analyzing response time performance.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers

  # Path segments that are ids: integers, UUIDs and long hex/base16 tokens
  @id_segment ~r</(\d+|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|[0-9a-f]{16,})(?=/|$)>i
  @min_samples 3

  @doc """
  Gets per-endpoint (method + raw path) duration totals for a given date range.
  Feed the rows to `top_endpoints/1` for the dashboard list. Unbounded on purpose:
  `/users/1`, `/users/2`, ... must all be summed before collapsing to `/users/:id`.

  Includes every non-error response (status < 400), so slow form posts that
  redirect show up next to the pages they render. Bots are kept: they are real load.
  """
  def slowest_pages(from_date, to_date) do
    RequestLog
    |> where([r], r.status_code < 400)
    |> Helpers.exclude_non_page()
    |> Helpers.exclude_dev()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], [r.method, r.path])
    |> select([r], %{
      method: r.method,
      path: r.path,
      total_ms: sum(r.duration_ms),
      hits: count(r.request_id)
    })
  end

  @doc """
  Collapses id segments (`/users/123` → `/users/:id`), then returns the `limit`
  endpoints with the highest average duration among those with at least
  `min_samples` requests, so one-off slow requests don't top the list.

  SQL can't do the id collapsing portably (no regex in SQLite), hence Elixir.
  """
  def top_endpoints(rows, min_samples \\ @min_samples, limit \\ 6) do
    rows
    |> Enum.group_by(&{&1.method, Regex.replace(@id_segment, &1.path, "/:id")})
    |> Enum.map(fn {{method, path}, group} ->
      total = group |> Enum.map(&to_number(&1.total_ms)) |> Enum.sum()
      hits = group |> Enum.map(& &1.hits) |> Enum.sum()
      %{method: method, path: path, duration: Float.round(total / hits, 2), hits: hits}
    end)
    |> Enum.filter(&(&1.hits >= min_samples))
    |> Enum.sort_by(&{-&1.duration, &1.path, &1.method})
    |> Enum.take(limit)
  end

  # MySQL returns SUM as a Decimal
  defp to_number(%Decimal{} = value), do: Decimal.to_float(value)
  defp to_number(value), do: value

  @doc """
  Gets slowest resources (non-page requests) for a given date range.
  """
  def slowest_resources(from_date, to_date) do
    RequestLog
    |> Helpers.filter_successful()
    |> Helpers.filter_static_files()
    |> Helpers.exclude_dev()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.path)
    |> select([r], %{
      path: r.path,
      duration: fragment("CAST(ROUND(AVG(?), 2) AS FLOAT(53))", r.duration_ms)
    })
    |> order_by([r], desc: fragment("CAST(AVG(?) AS FLOAT(53))", r.duration_ms))
    |> limit(6)
  end
end
