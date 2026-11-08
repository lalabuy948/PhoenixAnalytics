defmodule PhoenixAnalytics.Queries.Analytics.Charts.Heatmap do
  @moduledoc """
  Ecto-based queries for traffic by weekday and hour of day.
  """

  import Ecto.Query
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Helpers
  alias PhoenixAnalytics.Services.Utility

  @doc """
  Counts page views per weekday (0 = Sunday) and hour (0..23, UTC) for a given date range.
  Buckets without traffic are not returned.
  """
  def traffic_heatmap(from_date, to_date) do
    {weekday, hour} = buckets(Utility.database_type())

    RequestLog
    |> Helpers.page_views()
    |> Helpers.filter_by_date(from_date, to_date)
    |> group_by(^[weekday, hour])
    |> select(^%{weekday: weekday, hour: hour, hits: dynamic([r], count(r.request_id))})
    |> order_by(^[weekday, hour])
  end

  # Same expression in select and group_by keeps MySQL's ONLY_FULL_GROUP_BY happy
  defp buckets(:sqlite) do
    {dynamic([r], fragment("CAST(strftime('%w', ?) AS INTEGER)", r.inserted_at)),
     dynamic([r], fragment("CAST(strftime('%H', ?) AS INTEGER)", r.inserted_at))}
  end

  defp buckets(:mysql) do
    {dynamic([r], fragment("DAYOFWEEK(?) - 1", r.inserted_at)),
     dynamic([r], fragment("HOUR(?)", r.inserted_at))}
  end

  defp buckets(_postgres) do
    {dynamic([r], fragment("CAST(EXTRACT(DOW FROM ?) AS INTEGER)", r.inserted_at)),
     dynamic([r], fragment("CAST(EXTRACT(HOUR FROM ?) AS INTEGER)", r.inserted_at))}
  end
end
