defmodule PhoenixAnalytics.Web.Live.Components.DeviceChart do
  @moduledoc false

  use PhoenixAnalytics.Web, :live_component

  alias PhoenixAnalytics.Services.Cache

  alias PhoenixAnalytics.Queries.Analytics

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.react
        name="DeviceChart"
        dateRange={@date_range}
        chartData={@chart_data.result || []}
        chartTitle={@chart_title}
        footer={@footer}
        unit={@unit}
        socket={@socket}
      />
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       source: :devices,
       chart_title: "Device Usage",
       # bots are classified at track time; rows tracked before that keep their device type
       footer: "Page requests split by device type",
       unit: "Visits"
     )}
  end

  @impl true
  def update(assigns, socket) do
    previous = {socket.assigns[:date_range], socket.assigns.source}
    socket = assign(socket, assigns)
    %{date_range: date_range, source: source} = socket.assigns

    if previous != {date_range, source} do
      {:ok,
       assign_async(socket, :chart_data, fn ->
         {:ok, %{chart_data: chart_data(source, date_range)}}
       end)}
    else
      {:ok, socket}
    end
  end

  defp chart_data(source, %{from: from, to: to} = _date_range) do
    cache_key = "pie_chart:#{source}:#{from}:#{to}"

    Cache.fetch(cache_key, fn -> fetch_data(source, from, to) end)
  end

  defp fetch_data(source, from, to) do
    query =
      case source do
        :devices -> Analytics.devices_usage(from, to)
        :visitor_types -> Analytics.visitor_types(from, to)
      end

    for %{count: count} = row <- PhoenixAnalytics.Config.get_repo().all(query) do
      %{"name" => row[:device] || row[:type], "visits" => count}
    end
  end
end
