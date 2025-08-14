defmodule PhoenixAnalytics.Web.Live.Components.StatusChart do
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
        name="StatusChart"
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
    cache_key = "statuses_per_period:#{interval}:#{from}:#{to}"

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
    query = Analytics.statuses_per_period(from, to, interval)
    repo = PhoenixAnalytics.Config.get_repo()
    result = repo.all(query)

    case result do
      [] ->
        []

      {:error, reason} ->
        Telemetry.log_error(:fetch_data, reason)
        []

      _ ->
        for %{
              date: date,
              ok_200s: oks,
              redirects_300s: redirects,
              errors_400s: errors,
              fails_500s: fails
            } <- result do
          %{
            "date" => date,
            "oks" => convert_decimal(oks),
            "redirs" => convert_decimal(redirects),
            "errors" => convert_decimal(errors),
            "fails" => convert_decimal(fails)
          }
        end
    end
  end

  defp convert_decimal(decimal) do
    case decimal do
      %Decimal{} -> Decimal.to_float(decimal)
      value when is_number(value) -> value
      _ -> 0
    end
  end
end
