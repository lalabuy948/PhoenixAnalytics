defmodule PhoenixAnalytics.Queries.Helpers do
  @moduledoc """
  Ecto query helpers for PhoenixAnalytics analytics queries.

  This module provides helper functions for building Ecto queries
  instead of raw SQL string concatenation.
  """

  import Ecto.Query

  @static ~w(.js .css .png .jpg .jpeg .svg .gif .woff .woff2 .ttf .ico .txt .xml)
  @paths ~w(/uploads/ /assets/ /images/ /css/ /js/ /fonts/ /favicon.ico)
  @dev ~w(/phoenix/live_reload/ /dev/)

  @doc """
  Excludes non-page requests (static files, assets, etc.) from a query.
  """
  def exclude_non_page(query) do
    query
    |> exclude_static_files()
    |> exclude_asset_paths()
  end

  @doc """
  Excludes development-only paths from a query.
  """
  def exclude_dev(query) do
    query
    |> exclude_dev_paths()
  end

  @doc """
  Applies date range filtering to a query.
  """
  def filter_by_date(query, from_date, to_date) do
    query
    |> filter_from_date(from_date)
    |> filter_to_date(to_date)
  end

  @doc """
  Filters query to only include successful requests (status 200).
  """
  def filter_successful(query) do
    from(r in query, where: r.status_code == 200)
  end

  @doc """
  Filters query to only include GET requests.
  """
  def filter_get_requests(query) do
    from(r in query, where: r.method == "GET")
  end

  @doc """
  Filters query to only include 404 requests.
  """
  def filter_not_found(query) do
    from(r in query, where: r.status_code == 404)
  end

  @doc """
  Filters query to exclude internal referrers.
  """
  def filter_external_referrers(query, app_domain) do
    from(r in query,
      where:
        not like(r.referer, ^"%#{app_domain}%") and
          not like(r.referer, ^"%unknown%")
    )
  end

  # Private helper functions

  defp exclude_static_files(query) do
    Enum.reduce(@static, query, fn ext, q ->
      from(r in q, where: not like(r.path, ^"%#{ext}"))
    end)
  end

  defp exclude_asset_paths(query) do
    Enum.reduce(@paths, query, fn path, q ->
      from(r in q, where: not like(r.path, ^"%#{path}%"))
    end)
  end

  defp exclude_dev_paths(query) do
    Enum.reduce(@dev, query, fn path, q ->
      from(r in q, where: not like(r.path, ^"%#{path}%"))
    end)
  end

  defp filter_from_date(query, nil), do: query

  defp filter_from_date(query, from_date) do
    # Convert Date to NaiveDateTime if needed
    naive_from_date =
      case from_date do
        %Date{} -> NaiveDateTime.new!(from_date, ~T[00:00:00])
        %NaiveDateTime{} -> from_date
        date_string when is_binary(date_string) ->
          case NaiveDateTime.from_iso8601(date_string) do
            {:ok, naive_dt} -> naive_dt
            {:error, _} ->
              # Try parsing as date only first, then add time
              case Date.from_iso8601(String.slice(date_string, 0, 10)) do
                {:ok, date} -> NaiveDateTime.new!(date, ~T[00:00:00])
                {:error, _} -> from_date
              end
          end
        _ -> from_date
      end

    from(r in query, where: r.inserted_at >= ^naive_from_date)
  end

  defp filter_to_date(query, nil), do: query

  defp filter_to_date(query, to_date) do
    # Convert Date to NaiveDateTime if needed
    naive_to_date =
      case to_date do
        %Date{} -> NaiveDateTime.new!(to_date, ~T[23:59:59])
        %NaiveDateTime{} -> to_date
        date_string when is_binary(date_string) ->
          case NaiveDateTime.from_iso8601(date_string) do
            {:ok, naive_dt} -> naive_dt
            {:error, _} ->
              # Try parsing as date only first, then add time
              case Date.from_iso8601(String.slice(date_string, 0, 10)) do
                {:ok, date} -> NaiveDateTime.new!(date, ~T[23:59:59])
                {:error, _} -> to_date
              end
          end
        _ -> to_date
      end

    from(r in query, where: r.inserted_at <= ^naive_to_date)
  end


end
