defmodule PhoenixAnalytics.Web.Live.Components.VisitsChart do
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
        name="VisitsChart"
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
    interval = assigns.interval

    # Check if date_range or interval has changed
    should_refresh = 
      socket.assigns[:date_range] != date_range || 
      socket.assigns[:interval] != interval

    socket = assign(socket, assigns)

    if should_refresh do
      {:ok,
       assign_async(socket, :chart_data, fn -> {:ok, %{chart_data: chart_data(date_range, interval)}} end)}
    else
      {:ok, socket}
    end
  end

  defp chart_data(%{from: from, to: to} = _date_range, interval) do
    cache_key = "visits_per_period:#{interval}:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_data(from, to, interval) end)

    # Handle Cachex.Error structs that can't be JSON encoded
    case value do
      %Cachex.Error{} ->
        []

      _ ->
        value
    end
  end

  defp fetch_data(from, to, interval) do
    query = Analytics.visits_per_period(from, to, interval)
    repo = PhoenixAnalytics.Config.get_repo()
    result = repo.all(query)

    case result do
      [] ->
        []

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        []

      _ ->
        # Transform data to match frontend expectations
        Enum.map(result, fn %{date: date, visits: visits, unique_visitors: unique_visitors} ->
          %{
            "date" => date,
            "total_visits" => visits,
            "unique_visits" => unique_visitors
          }
        end)
    end
  end
end
