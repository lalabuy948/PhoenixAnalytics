defmodule PhoenixAnalytics.Web.Live.Components.ResChart do
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
        name="ResChart"
        dateRange={@date_range}
        chartData={@chart_data.result || []}
        chartTitle={@chart_title}
        socket={@socket}
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    data_source = assigns.source
    date_range = assigns.date_range

    {:ok,
     assign(socket, assigns)
     |> assign_async(:chart_data, fn ->
       {:ok, %{chart_data: chart_data(data_source, date_range)}}
     end)}
  end

  defp chart_data(source, %{from: from, to: to} = _date_range) do
    cache_key = "slowest_chart:#{source}:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_data(source, from, to) end)

    value
  end

  defp fetch_data(source, from, to) do
    query =
      case source do
        :pages -> Analytics.slowest_pages(from, to)
        :resources -> Analytics.slowest_resources(from, to)
      end

    result = Repo.execute_fetch({query, []})

    case result do
      [] ->
        []

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        []

      _ ->
        for [%{"path" => path, "duration" => duration}] <- result do
          %{"path" => path, "duration" => duration}
        end
    end
  end
end
