defmodule PhoenixAnalytics.Web.Live.Components.RequestsChart do
  @moduledoc false

  use PhoenixAnalytics.Web, :live_component

  alias PhoenixAnalytics.Services.Cache
  alias PhoenixAnalytics.Services.Telemetry

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

    # Check if date_range or interval has changed
    should_refresh = 
      socket.assigns[:date_range] != date_range || 
      socket.assigns[:interval] != interval

    socket = assign(socket, assigns)

    if should_refresh do
      {:ok,
       assign_async(socket, :chart_data, fn ->
         {:ok, %{chart_data: chart_data(date_range, interval)}}
       end)}
    else
      {:ok, socket}
    end
  end

  def chart_data(%{from: from, to: to} = _date_range, interval) do
    cache_key = "requests_chart:#{interval}:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_chart_data(from, to, interval) end)

    # Handle Cachex.Error structs that can't be JSON encoded
    case value do
      %Cachex.Error{} ->
        []

      _ ->
        value
    end
  end

  defp fetch_chart_data(from, to, interval) do
    query = Analytics.total_requests_per_period(from, to, interval)
    repo = PhoenixAnalytics.Config.get_repo()
    result = repo.all(query)

    case result do
      [] ->
        []

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        []

      _ ->
        for %{date: date, hits: hits} <- result do
          %{"date" => date, "hits" => hits}
        end
    end
  end
end
