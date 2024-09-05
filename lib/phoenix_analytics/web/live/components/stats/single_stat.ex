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
        statData={@stat_data}
        statUnit={@stat_unit}
        statTitle={@stat_title}
        dateRange={@date_range}
        chartData={@chart_data}
        socket={@socket}
      />
    </div>
    """
  end

  def update(assigns, socket) do
    stat_data = stat_data(assigns.source, assigns.date_range)
    chart_data = chart_data(assigns.source, assigns.date_range)

    stat_title =
      case assigns.source do
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
     |> assign(:stat_data, stat_data)
     |> assign(:chart_data, chart_data)}
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
