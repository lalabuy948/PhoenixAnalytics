defmodule PhoenixAnalytics.Services.Telemetry do
  def log_error(error, reason) do
    :telemetry.execute([:phoenix_analytics, :error], %{}, %{error: error, reason: reason})
  end
end
