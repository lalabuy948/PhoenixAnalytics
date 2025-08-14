defmodule PhoenixAnalytics.Queries.Analytics.Charts.Device do
  @moduledoc """
  Ecto-based queries for device analytics.

  This module provides functions to generate Ecto queries for
  analyzing device usage patterns.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers

  @doc """
  Gets device usage statistics for a given date range.
  """
  def devices_usage(from_date, to_date) do
    RequestLog
    |> Helpers.exclude_non_page()
    |> Helpers.exclude_dev()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by([r], r.device_type)
    |> select([r], %{
      device: r.device_type,
      count: count(r.request_id)
    })
    |> order_by([r], desc: count(r.request_id))
  end
end