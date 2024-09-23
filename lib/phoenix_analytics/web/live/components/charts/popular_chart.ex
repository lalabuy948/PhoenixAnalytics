defmodule PhoenixAnalytics.Web.Live.Components.PopularChart do
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
        name="PopularChart"
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
    cache_key = "popular_chart:#{source}:#{from}:#{to}"

    {_, value} = Cache.fetch(cache_key, fn -> fetch_data(source, from, to) end)

    value
  end

  defp fetch_data(source, from, to) do
    query =
      case source do
        :pages -> Analytics.popular_pages(from, to)
        :referers -> Analytics.popular_referer(from, to)
        :not_founds -> Analytics.popular_not_found(from, to)
      end

    result = Repo.execute_fetch({query, []})

    case result do
      [] ->
        []

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        []

      _ ->
        for [%{"source" => source, "visits" => visits}] <- result do
          %{"source" => source, "visits" => visits}
        end
    end
  end
end
