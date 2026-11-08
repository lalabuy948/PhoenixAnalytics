defmodule PhoenixAnalytics.Web.Live.Components.HeatmapChart do
  @moduledoc false

  use PhoenixAnalytics.Web, :live_component

  alias PhoenixAnalytics.Queries.Analytics
  alias PhoenixAnalytics.Services.Cache

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.react
        name="HeatmapChart"
        dateRange={@date_range}
        chartData={@chart_data.result || []}
        socket={@socket}
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    should_refresh = socket.assigns[:date_range] != assigns.date_range
    socket = assign(socket, assigns)
    date_range = socket.assigns.date_range

    if should_refresh do
      {:ok,
       assign_async(socket, :chart_data, fn ->
         {:ok, %{chart_data: chart_data(date_range)}}
       end)}
    else
      {:ok, socket}
    end
  end

  defp chart_data(%{from: from, to: to}) do
    Cache.fetch("traffic_heatmap:#{from}:#{to}", fn ->
      for %{weekday: weekday, hour: hour, hits: hits} <-
            PhoenixAnalytics.Config.get_repo().all(Analytics.traffic_heatmap(from, to)) do
        %{"weekday" => weekday, "hour" => hour, "hits" => hits}
      end
    end)
  end
end
