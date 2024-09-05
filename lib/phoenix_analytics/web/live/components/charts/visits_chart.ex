defmodule PhoenixAnalytics.Web.Live.Components.VisitsChart do
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
      <.react name="VisitsChart" dateRange={@date_range} chartData={@chart_data} socket={@socket} />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    date_range = assigns.date_range
    interval = assigns.interval

    {:ok,
     assign(socket, assigns)
     |> assign(:chart_data, chart_data(date_range, interval))}
  end

  defp chart_data(%{from: from, to: to} = _date_range, interval) do
    cache_key = "visits_per_period:#{interval}:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_data(from, to, interval) end)

    value
  end

  defp fetch_data(from, to, interval) do
    query = Analytics.visits_per_period(from, to, interval)
    result = Repo.execute_fetch({query, []})

    case result do
      [] ->
        []

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        []

      _ ->
        for [date | [total_visits, unique_visits | _]] <- result do
          %{
            "date" => date,
            "total" => total_visits,
            "unique" => unique_visits
          }
        end
    end
  end
end
