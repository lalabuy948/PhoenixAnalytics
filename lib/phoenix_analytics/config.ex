defmodule PhoenixAnalytics.Config do
  @moduledoc """
  Configuration module for PhoenixAnalytics.

  This module provides configuration functions for Phoenix Analytics
  that work with the user's existing Ecto repository.
  """

  @doc """
  Gets the user's configured Ecto repository.
  """
  def get_repo do
    get_config(:repo) || raise """
    Phoenix Analytics requires a repository to be configured.
    
    Please add the following to your config:
    
    config :phoenix_analytics,
      repo: MyApp.Repo,
      app_domain: "example.com"
    """
  end

  @doc """
  Gets the application domain for filtering external referrers.
  """
  def get_app_domain do
    get_config(:app_domain, "localhost")
  end

  @doc """
  Gets the cache TTL in seconds.
  """
  def get_cache_ttl do
    get_config(:cache_ttl, 60)
  end

  @doc """
  Gets the OTP app name (if needed for specific configurations).
  """
  def get_otp_app do
    get_config(:otp_app, :phoenix_analytics)
  end

  # Private helper functions

  defp get_config(key, default \\ nil) do
    case Application.fetch_env(:phoenix_analytics, key) do
      {:ok, value} -> value
      :error -> default
    end
  end
end