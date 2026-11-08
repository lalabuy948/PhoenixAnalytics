defmodule PhoenixAnalytics.Web.Live.Components.PopularChart do
  @moduledoc false

  use PhoenixAnalytics.Web, :live_component

  alias PhoenixAnalytics.Services.Cache

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
        footer={assigns[:footer]}
        socket={@socket}
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    data_source = assigns.source
    date_range = assigns.date_range

    # Check if date_range has changed
    should_refresh = socket.assigns[:date_range] != date_range

    socket = assign(socket, assigns)

    if should_refresh do
      {:ok,
       assign_async(socket, :chart_data, fn ->
         {:ok, %{chart_data: chart_data(data_source, date_range)}}
       end)}
    else
      {:ok, socket}
    end
  end

  defp chart_data(source, %{from: from, to: to} = _date_range) do
    cache_key = "popular_chart:#{source}:#{from}:#{to}"

    Cache.fetch(cache_key, fn -> fetch_data(source, from, to) end)
  end

  defp fetch_data(:time_to_second_page, from, to) do
    from
    |> Analytics.time_to_second_page(to)
    |> PhoenixAnalytics.Config.get_repo().all()
    |> Analytics.second_page_buckets()
  end

  defp fetch_data(:referers, from, to) do
    from
    |> Analytics.popular_referer(to)
    |> PhoenixAnalytics.Config.get_repo().all()
    |> Analytics.top_referers()
  end

  defp fetch_data(:referer_landings, from, to) do
    from
    |> Analytics.referer_landing_pages(to)
    |> PhoenixAnalytics.Config.get_repo().all()
    |> Analytics.top_referer_landings()
  end

  defp fetch_data(source, from, to) do
    query =
      case source do
        :pages -> Analytics.popular_pages(from, to)
        :not_founds -> Analytics.popular_not_found(from, to)
        :entry_pages -> Analytics.entry_pages(from, to)
        :exit_pages -> Analytics.exit_pages(from, to)
        :pages_per_visit -> Analytics.pages_per_visit_distribution(from, to)
      end

    # Let DB errors raise: assign_async renders the empty fallback and nothing gets cached
    PhoenixAnalytics.Config.get_repo().all(query)
  end
end
