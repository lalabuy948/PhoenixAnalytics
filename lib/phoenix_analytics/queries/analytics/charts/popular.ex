defmodule PhoenixAnalytics.Queries.Analytics.Charts.Popular do
  @moduledoc """
  Ecto-based queries for popular pages, referrers, and 404 pages.

  This module provides functions to generate Ecto queries for
  analyzing popular content and traffic sources.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers

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
end
