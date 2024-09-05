defmodule PhoenixAnalytics.Services.Utility do
  @moduledoc """
  A helper module containing static utility functions for Phoenix Analytics.

  This module provides various utility functions that are used across the
  Phoenix Analytics application. It includes functions for timestamp generation
  and device type detection based on user agent strings.
  """

  @doc """
  Returns the current UTC timestamp in DuckDB format.

  This function generates a timestamp string that is compatible with DuckDB's
  TIMESTAMP data type. The timestamp is in UTC and includes millisecond precision.

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
      String.contains?(agent_string, "Mobile") -> "mobile"
      String.contains?(agent_string, "Pad") -> "tablet"
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
  def uuid, do: UUID.uuid4()
end
