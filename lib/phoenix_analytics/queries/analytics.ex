defmodule PhoenixAnalytics.Queries.Analytics do
  @moduledoc """
  Main analytics queries module for PhoenixAnalytics.

  This module provides access to all analytics query functions
  organized by category (charts, stats, etc.).
  """

  # Import all the analytics query modules
  alias PhoenixAnalytics.Queries.Analytics.{
    Charts.Popular,
    Charts.Device,
    Charts.Requests,
    Charts.Slowest,
    Charts.Statuses,
    Charts.Visits,
    Stats.Stat,
    Stats.PerPeriod
  }

  # Re-export all the functions for easy access
  defdelegate popular_pages(from_date, to_date), to: Popular
  defdelegate popular_referer(from_date, to_date), to: Popular
  defdelegate popular_not_found(from_date, to_date), to: Popular
  defdelegate popular_user_agents(from_date, to_date), to: Popular
  defdelegate popular_device_types(from_date, to_date), to: Popular

  # Stats functions
  defdelegate unique_visitors(from_date, to_date), to: Stat
  defdelegate total_pageviews(from_date, to_date), to: Stat
  defdelegate total_requests(from_date, to_date), to: Stat
  defdelegate average_views_per_visit(from_date, to_date), to: Stat
  defdelegate average_visit_duration(from_date, to_date, interval \\ "day"), to: Stat
  defdelegate bounce_rate(from_date, to_date), to: Stat
  defdelegate average_response_time(from_date, to_date), to: Stat
  defdelegate status_code_distribution(from_date, to_date), to: Stat
  defdelegate device_type_distribution(from_date, to_date), to: Stat

  # Chart functions
  defdelegate devices_usage(from_date, to_date), to: Device
  defdelegate statuses_per_period(from_date, to_date, interval), to: Statuses
  defdelegate total_requests_per_period(from_date, to_date, interval), to: Requests
  defdelegate slowest_pages(from_date, to_date), to: Slowest
  defdelegate slowest_resources(from_date, to_date), to: Slowest
  defdelegate visits_per_period(from_date, to_date, interval), to: Visits

  # Period-based stats functions
  defdelegate unique_visitors_per_period_limited(from_date, to_date), to: PerPeriod
  defdelegate total_pageviews_per_period_limited(from_date, to_date), to: PerPeriod
  defdelegate total_requests_per_period_limited(from_date, to_date), to: Requests
  defdelegate views_per_visit_per_period_limited(from_date, to_date), to: PerPeriod
  defdelegate visit_duration_per_period_limited(from_date, to_date), to: PerPeriod
  defdelegate bounce_rate_per_period_limited(from_date, to_date), to: PerPeriod
end
