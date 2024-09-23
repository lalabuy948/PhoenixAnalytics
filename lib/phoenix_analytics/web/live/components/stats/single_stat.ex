defmodule PhoenixAnalytics.Web.Live.Components.SingleStat do
  @moduledoc false

  use PhoenixAnalytics.Web, :live_component

  alias PhoenixAnalytics.Services.Cache
  alias PhoenixAnalytics.Services.Telemetry
  alias PhoenixAnalytics.Repo
  alias PhoenixAnalytics.Queries.Analytics

  def render(assigns) do
    ~H"""
    <div>
      <.react
        name="SingleStat"
        statUnit={@stat_unit}
        statTitle={@stat_title}
        dateRange={@date_range}
        statData={@stat_data.result || 0}
        chartData={@chart_data.result || []}
        socket={@socket}
      />
    </div>
    """
  end

  def update(assigns, socket) do
    source = assigns.source
    date_range = assigns.date_range

    stat_title =
      case source do
        :unique_visitors -> "Unique visitors"
        :total_pageviews -> "Total Pageviews"
        :total_requests -> "Total Requests"
        :views_per_visit -> "Views per Visit"
        :visit_duration -> "Visit Duration"
        :bounce_rate -> "Bounce Rate"
      end

    {:ok,
     assign(socket, assigns)
     |> assign(:stat_title, stat_title)
     |> assign_async(:stat_data, fn ->
       {:ok, %{stat_data: stat_data(source, date_range)}}
     end)
     |> assign_async(:chart_data, fn ->
       {:ok, %{chart_data: chart_data(source, date_range)}}
     end)}
  end

  defp stat_data(source, %{from: from, to: to} = _date_range) do
    cache_key = "stat:#{source}:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_stat_data(source, from, to) end)

    value
  end

  defp fetch_stat_data(source, from, to) do
    query =
      case source do
        :unique_visitors -> Analytics.unique_visitors(from, to)
        :total_pageviews -> Analytics.total_pageviews(from, to)
        :total_requests -> Analytics.total_requests(from, to)
        :views_per_visit -> Analytics.average_views_per_visit(from, to)
        :visit_duration -> Analytics.average_visit_duration(from, to)
        :bounce_rate -> Analytics.bounce_rate(from, to)
      end

    result = Repo.execute_fetch({query, []})

    case result do
      [] ->
        0

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        0

      [[formatted | _] | _] ->
        formatted
    end
  end

  defp chart_data(source, %{from: from, to: to} = _date_range) do
    cache_key = "stat_chart:#{source}:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_chart_data(source, from, to) end)

    value
  end

  defp fetch_chart_data(source, from, to) do
    query =
      case source do
        :unique_visitors -> Analytics.unique_visitors_per_period_limited(from, to)
        :total_pageviews -> Analytics.total_pageviews_per_period_limited(from, to)
        :total_requests -> Analytics.total_requests_per_period_limited(from, to)
        :views_per_visit -> Analytics.views_per_visit_per_period_limited(from, to)
        :visit_duration -> Analytics.visit_duration_per_period_limited(from, to)
        :bounce_rate -> Analytics.bounce_rate_per_period_limited(from, to)
      end

    result = Repo.execute_fetch({query, []})

    case result do
      [] ->
        []

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        []

      _ ->
        for [date, hits] <- result do
          %{"date" => date, "hits" => hits}
        end
    end
  end
end
