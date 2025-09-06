defmodule PhoenixAnalytics.Services.Utility do
  @moduledoc """
  A helper module containing static utility functions for Phoenix Analytics.

  This module provides various utility functions that are used across the
  Phoenix Analytics application. It includes functions for timestamp generation
  and device type detection based on user agent strings.
  """

  @doc """
  Returns the current UTC timestamp in database-compatible format.

  This function generates a timestamp string that is compatible with standard
  database TIMESTAMP data types. The timestamp is in UTC and includes millisecond precision.

  ## Examples

      iex> PhoenixAnalytics.Services.Utility.inserted_at()
      "2023-05-15 14:30:45.123"

  Returns a string in the format "YYYY-MM-DD HH:MM:SS.mmm".
  """
  def inserted_at do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:millisecond)
    |> NaiveDateTime.to_string()
    |> String.replace("T", " ")
  end

  @doc """
  Determines the device type based on the user agent string.

  This function provides a simple and fast way to categorize devices as mobile,
  tablet, or desktop based on the user agent string. It was implemented as a
  lightweight alternative to ua_parser and ua_inspector, which were found to be
  excessively slow for this use case.

  While this method is not as comprehensive as full-fledged user agent parsing
  libraries, it offers a quick classification that is sufficient for many
  analytics purposes.

  ## Parameters

    * agent_string - The user agent string to analyze

  ## Returns

  A string indicating the device type:
    * "mobile" for mobile devices
    * "tablet" for tablet devices
    * "desktop" for desktop devices or any unrecognized device type

  ## Examples

      iex> PhoenixAnalytics.Services.Utility.get_device_type("Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1")
      "mobile"

      iex> PhoenixAnalytics.Services.Utility.get_device_type("Mozilla/5.0 (iPad; CPU OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1")
      "tablet"

      iex> PhoenixAnalytics.Services.Utility.get_device_type("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
      "desktop"
  """
  def get_device_type(agent_string) do
    cond do
      String.contains?(agent_string, "Pad") -> "tablet"
      String.contains?(agent_string, "Mobile") -> "mobile"
      true -> "desktop"
    end
  end

  @doc """
  Generates a new UUID (Universally Unique Identifier).

  This function creates a version 4 UUID, which is randomly generated.

  ## Examples

      iex> PhoenixAnalytics.Services.Utility.uuid()
      "550e8400-e29b-41d4-a716-446655440000"

  Returns a string representation of the UUID.
  """
  def uuid, do: UUIDv7.generate()

  @doc """
  Determines the current database type based on configuration.

  This function checks the application environment for database configurations
  to determine the current database type being used.

  ## Returns

  An atom indicating the database type:
    * `:postgres` if PostgreSQL is configured
    * `:sqlite` if SQLite is configured
    * `:mysql` if MySQL is configured
    * `:postgres` as a fallback if no valid configuration is found

  ## Examples

      iex> PhoenixAnalytics.Services.Utility.database_type()
      :postgres

  """
  def database_type() do
    # Get the repo from config and check its adapter
    repo = PhoenixAnalytics.Config.get_repo()

    cond do
      repo && repo.__adapter__() == Ecto.Adapters.SQLite3 -> :sqlite
      repo && repo.__adapter__() == Ecto.Adapters.Postgres -> :postgres
      repo && repo.__adapter__() == Ecto.Adapters.MyXQL -> :mysql
      has_config?(:postgres_conn) -> :postgres
      has_config?(:sqlite_path) -> :sqlite
      has_config?(:mysql_conn) -> :mysql
      true -> :postgres
    end
  end

  @doc """
  Checks if a specific configuration key exists and has a value.

  ## Parameters

    * key - The configuration key to check

  ## Returns

  A boolean indicating whether the configuration exists and has a value.

  ## Examples

      iex> PhoenixAnalytics.Services.Utility.has_config?(:postgres_conn)
      true

  """
  def has_config?(key) do
    case get_config(key) do
      :error -> false
      nil -> false
      _ -> true
    end
  end

  @doc """
  Gets a configuration value with an optional default.

  ## Parameters

    * key - The configuration key to retrieve
    * default - The default value if the key is not found

  ## Returns

  The configuration value or the default value.

  ## Examples

      iex> PhoenixAnalytics.Services.Utility.get_config(:pool_size, 10)
      10

  """
  def get_config(key, default \\ nil) do
    case Application.fetch_env(:phoenix_analytics, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  # Legacy function for backward compatibility
  def mode(), do: database_type()
end
