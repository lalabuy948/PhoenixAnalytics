defmodule PhoenixAnalytics.Web.Live.Dashboard do
  @moduledoc false

  use PhoenixAnalytics.Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    thirty_days_ago = today |> Date.add(-30)

    default_to = today |> Date.to_string() |> Kernel.<>(" 23:59:59")
    default_from = thirty_days_ago |> Date.to_string() |> Kernel.<>(" 00:00:00")

    range = %{from: default_from, to: default_to}
    default_interval = "day"

    {:ok, socket |> assign(:date_range, range) |> assign(:interval, default_interval)}
  end

  @impl true
  def handle_event("set_date", %{"value" => %{"from" => from, "to" => to}}, socket) do
    {:noreply, assign(socket, :date_range, %{from: from, to: to})}
  end

  @impl true
  def handle_event("set_interval", %{"value" => %{"interval" => interval}}, socket) do
    {:noreply, assign(socket, :interval, interval)}
  end
end
