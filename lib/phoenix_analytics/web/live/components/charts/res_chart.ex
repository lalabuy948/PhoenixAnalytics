defmodule PhoenixAnalytics.Web.Live.Components.ResChart do
  @moduledoc false

  use PhoenixAnalytics.Web, :live_component

  alias PhoenixAnalytics.Services.Cache

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
    cache_key = "slowest_chart:#{source}:#{from}:#{to}"

    Cache.fetch(cache_key, fn -> fetch_data(source, from, to) end)
  end

  defp fetch_data(:pages, from, to) do
    from
    |> Analytics.slowest_pages(to)
    |> PhoenixAnalytics.Config.get_repo().all()
    |> Analytics.top_endpoints()
    |> Enum.map(&%{"path" => label(&1), "duration" => &1.duration})
  end

  defp fetch_data(:resources, from, to) do
    for row <- PhoenixAnalytics.Config.get_repo().all(Analytics.slowest_resources(from, to)) do
      %{"path" => label(row), "duration" => row.duration}
    end
  end

  @doc false
  def label(%{method: method, path: path}), do: "#{method} #{path}"
  def label(%{path: path}), do: path
end
