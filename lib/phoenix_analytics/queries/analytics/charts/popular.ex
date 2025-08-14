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
    |> Helpers.filter_successful()
    |> Helpers.exclude_non_page()
    |> Helpers.exclude_dev()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.path)
    |> select([r], %{
      source: r.path,
      visits: count(r.request_id)
    })
    |> order_by([r], desc: count(r.request_id))
    |> limit(9)
  end

  @doc """
  Gets popular external referrers for a given date range.
  """
  def popular_referer(from_date, to_date) do
    app_domain = PhoenixAnalytics.Config.get_app_domain()
    
    RequestLog
    |> Helpers.filter_external_referrers(app_domain)
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.referer)
    |> select([r], %{
      source: r.referer,
      visits: count(r.request_id)
    })
    |> order_by([r], desc: count(r.request_id))
    |> limit(9)
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
    |> order_by([r], desc: count(r.request_id))
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
    |> order_by([r], desc: count(r.request_id))
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
    |> order_by([r], desc: count(r.request_id))
    |> limit(9)
  end
end
