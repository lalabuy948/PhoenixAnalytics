defmodule PhoenixAnalytics.Web.Live.Components.RequestsChart do
  @moduledoc false

  use PhoenixAnalytics.Web, :live_component

  alias PhoenixAnalytics.Services.Cache
  alias PhoenixAnalytics.Services.Telemetry
  alias PhoenixAnalytics.Repo
  alias PhoenixAnalytics.Queries.Analytics

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.react
        name="RequestsChart"
        dateRange={@date_range}
        chartData={@chart_data.result || []}
        socket={@socket}
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    interval = assigns.interval
    date_range = assigns.date_range

    {:ok,
     assign(socket, assigns)
     |> assign_async(:chart_data, fn ->
       {:ok, %{chart_data: chart_data(date_range, interval)}}
     end)}
  end

  def chart_data(%{from: from, to: to} = _date_range, interval) do
    cache_key = "requests_chart:#{interval}:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_chart_data(from, to, interval) end)

    value
  end

  defp fetch_chart_data(from, to, interval) do
    query = Analytics.total_requests_per_period(from, to, interval)
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
