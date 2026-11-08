defmodule PhoenixAnalytics.Queries.Analytics.Charts.Popular do
  @moduledoc """
  Ecto-based queries for popular pages, referrers, and 404 pages.

  This module provides functions to generate Ecto queries for
  analyzing popular content and traffic sources.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers
  alias PhoenixAnalytics.Services.Utility

  # App domain will be retrieved at runtime from config

  @doc """
  Gets popular pages for a given date range.
  """
  def popular_pages(from_date, to_date) do
    RequestLog
    |> Helpers.page_views()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.path)
    |> select([r], %{
      source: r.path,
      visits: count(r.request_id)
    })
    |> order_by([r], desc: count(r.request_id), asc: r.path)
    |> limit(9)
  end

  @doc """
  Gets visit counts per raw referer URL for a given date range (bots, Direct and
  blank referers excluded). Feed the rows to `top_referers/1`, which groups them
  by host and drops internal referers (portable SQL can't parse URLs).
  """
  def popular_referer(from_date, to_date) do
    RequestLog
    |> Helpers.exclude_bots()
    |> Helpers.filter_has_referer()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.referer)
    |> select([r], %{referer: r.referer, visits: count(r.request_id)})
  end

  @doc """
  Groups `popular_referer/2` rows by host (without "www."), drops referers from
  the app's own domain and its subdomains, and returns the top `limit` hosts.
  """
  def top_referers(rows, limit \\ 9) do
    top_external(rows, &referer_host(&1.referer), limit)
  end

  @doc """
  Gets popular 404 pages for a given date range.
  """
  def popular_not_found(from_date, to_date) do
    RequestLog
    |> Helpers.filter_not_found()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.path)
    |> select([r], %{
      source: r.path,
      visits: count(r.request_id)
    })
    |> order_by([r], desc: count(r.request_id), asc: r.path)
    |> limit(9)
  end

  @doc """
  Gets popular user agents for a given date range.
  """
  def popular_user_agents(from_date, to_date) do
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.user_agent)
    |> select([r], %{
      source: r.user_agent,
      visits: count(r.request_id)
    })
    |> order_by([r], desc: count(r.request_id), asc: r.user_agent)
    |> limit(9)
  end

  @doc """
  Gets popular device types for a given date range.
  """
  def popular_device_types(from_date, to_date) do
    RequestLog
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.device_type)
    |> select([r], %{
      source: r.device_type,
      visits: count(r.request_id)
    })
    |> order_by([r], desc: count(r.request_id), asc: r.device_type)
    |> limit(9)
  end

  @doc """
  Gets the most common first page of a session for a given date range.

  Sessions are clipped to the range: a session that started before `from_date`
  counts its first in-range page view as its entry (same for exits after `to_date`).
  Cookie-less clients (bots, curl) get a new session per request, so their
  landing pages count as both entry and exit.
  """
  def entry_pages(from_date, to_date), do: session_boundary_pages(from_date, to_date, :asc)

  @doc """
  Gets the most common last page of a session for a given date range.
  See `entry_pages/2` for how sessions are clipped to the range.
  """
  def exit_pages(from_date, to_date), do: session_boundary_pages(from_date, to_date, :desc)

  @doc """
  Gets (referer URL, landing page) visit counts for sessions whose first page view
  in the range came with a referer. Feed the rows to `top_referer_landings/1`.

  Only the landing row's referer counts: a session that starts Direct or from an
  internal page never counts, even if a later page view has an external referer.
  """
  def referer_landing_pages(from_date, to_date) do
    from_date
    |> session_boundaries(to_date, :asc)
    |> Helpers.filter_has_referer()
    |> group_by([p], [p.referer, p.path])
    |> select([p], %{referer: p.referer, path: p.path, visits: count()})
  end

  @doc """
  Like `top_referers/2`, but labels rows "host → /path".
  """
  def top_referer_landings(rows, limit \\ 9) do
    top_external(
      rows,
      &"#{referer_host(&1.referer)} → #{&1.path}",
      &referer_host(&1.referer),
      limit
    )
  end

  @second_page_buckets ["under 10s", "10-30s", "30-60s", "1-2 min", "2 min+"]

  @doc """
  Counts visits by the time between their first and second page view, as bucket
  numbers 1..5 (see `second_page_buckets/1` for labels). Single-page visits are not counted.

  Sessions are clipped to the range like `entry_pages/2`: a session straddling the
  range start is measured from its first in-range page view. JSON GETs count as
  page views (see `Helpers.page_views/1`), so an API call right after load can
  land in "under 10s".
  """
  def time_to_second_page(from_date, to_date) do
    gaps =
      from(p in session_boundaries(from_date, to_date, :asc),
        where: not is_nil(p.next_at),
        select: ^%{gap: gap_seconds(Utility.database_type())}
      )

    buckets =
      from(g in subquery(gaps),
        select: %{
          bucket:
            fragment(
              "CASE WHEN ? < 10 THEN 1 WHEN ? < 30 THEN 2 WHEN ? < 60 THEN 3 WHEN ? < 120 THEN 4 ELSE 5 END",
              g.gap,
              g.gap,
              g.gap,
              g.gap
            )
        }
      )

    from(b in subquery(buckets),
      group_by: b.bucket,
      select: %{bucket: b.bucket, visits: count()},
      order_by: b.bucket
    )
  end

  @doc """
  Labels `time_to_second_page/2` rows, filling empty buckets with 0 visits so the
  distribution keeps its shape. Returns `[]` when there are no multi-page visits.
  """
  def second_page_buckets([]), do: []

  def second_page_buckets(rows) do
    visits = Map.new(rows, &{&1.bucket, &1.visits})

    for {label, bucket} <- Enum.with_index(@second_page_buckets, 1) do
      %{source: label, visits: Map.get(visits, bucket, 0)}
    end
  end

  # Whole seconds between a session's first page view and the next one
  defp gap_seconds(:sqlite),
    do:
      dynamic(
        [p],
        fragment("CAST(ROUND((julianday(?) - julianday(?)) * 86400) AS INTEGER)", p.next_at, p.at)
      )

  defp gap_seconds(:mysql),
    do: dynamic([p], fragment("TIMESTAMPDIFF(SECOND, ?, ?)", p.at, p.next_at))

  defp gap_seconds(_postgres),
    do: dynamic([p], fragment("EXTRACT(EPOCH FROM (? - ?))", p.next_at, p.at))

  @doc """
  Returns the referer's host without "www.", or the raw referer when it has none
  (e.g. "newsletter").
  """
  def referer_host(referer) do
    case URI.parse(referer) do
      %URI{host: host} when is_binary(host) and host != "" ->
        host |> String.downcase() |> String.replace_prefix("www.", "")

      _ ->
        referer
    end
  end

  # Unbounded on purpose: every raw URL must be summed before taking the top
  # hosts, or unique-per-click referers (t.co/abc, ?id=N) get undercounted.
  defp top_external(rows, label_fun, host_fun \\ nil, limit) do
    host_fun = host_fun || label_fun
    app_domain = PhoenixAnalytics.Config.get_app_domain()

    rows
    |> Enum.reject(&internal_host?(host_fun.(&1), app_domain))
    |> Enum.group_by(label_fun, & &1.visits)
    |> Enum.map(fn {label, visits} -> %{source: label, visits: Enum.sum(visits)} end)
    |> Enum.sort_by(&{-&1.visits, &1.source})
    |> Enum.take(limit)
  end

  defp internal_host?(host, app_domain),
    do: host == app_domain or String.ends_with?(host, "." <> app_domain)

  defp session_boundary_pages(from_date, to_date, direction) do
    from(p in session_boundaries(from_date, to_date, direction),
      group_by: p.path,
      select: %{source: p.path, visits: count()},
      order_by: [desc: count(), asc: p.path],
      limit: 9
    )
  end

  # First (:asc) or last (:desc) page view of every session in the range
  defp session_boundaries(from_date, to_date, direction) do
    # inserted_at has 1s precision: the session's page counter, then request_id, break ties
    page_views = RequestLog |> Helpers.page_views() |> Helpers.filter_by_date(from_date, to_date)

    ranked =
      from(r in page_views,
        where: not is_nil(r.session_id),
        windows: [
          session: [
            partition_by: r.session_id,
            order_by: [
              {^direction, r.inserted_at},
              {^direction, r.session_page_views},
              {^direction, r.request_id}
            ]
          ]
        ],
        select: %{
          path: r.path,
          referer: r.referer,
          at: r.inserted_at,
          # next row in window order: the 2nd page view for :asc
          next_at: over(lead(r.inserted_at), :session),
          rank: over(row_number(), :session)
        }
      )

    from(p in subquery(ranked), where: p.rank == 1)
  end
end
