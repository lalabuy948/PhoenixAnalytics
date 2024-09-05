defmodule PhoenixAnalytics.Services.Telemetry do
  def log_success(event) do
    :telemetry.execute([:phoenix_analytics, :success], %{}, %{event: event})
  end

  def log_error(error, reason) do
    :telemetry.execute([:phoenix_analytics, :error], %{}, %{error: error, reason: reason})
  end
end
