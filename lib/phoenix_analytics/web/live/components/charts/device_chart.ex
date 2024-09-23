defmodule PhoenixAnalytics.Web.Live.Components.DeviceChart do
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
        name="DeviceChart"
        dateRange={@date_range}
        chartData={@chart_data.result || []}
        socket={@socket}
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    date_range = assigns.date_range

    {:ok,
     assign(socket, assigns)
     |> assign_async(:chart_data, fn ->
       {:ok, %{chart_data: chart_data(date_range)}}
     end)}
  end

  defp chart_data(%{from: from, to: to} = _date_range) do
    cache_key = "devices_usage:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_data(from, to) end)

    value
  end

  defp fetch_data(from, to) do
    query = Analytics.devices_usage(from, to)
    result = Repo.execute_fetch({query, []})

    case result do
      [] ->
        []

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        []

      _ ->
        for [device, visits | _] <- result do
          %{"device" => device, "visits" => visits}
        end
    end
  end
end
