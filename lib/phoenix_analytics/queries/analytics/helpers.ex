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
  Keeps only page views: successful GETs of non-asset, non-dev paths.

  Known limitation: JSON/XHR GETs (e.g. `/api/...`) also count, since rows don't record
  whether the response was HTML. The fix is persisting an `is_page` flag at track time.
  """
  def page_views(query) do
    query
    |> exclude_bots()
    |> filter_get_requests()
    |> filter_successful()
    |> exclude_non_page()
    |> exclude_dev()
  end

  @doc """
  Restricts a query grouped by session to visits: sessions with an id and at least
  one HTML page view. Asset-only or API-only sessions (counter 0) are not visits.
  Shared by bounce rate, views per visit, visit duration and the pages-per-visit chart
  so their numbers agree.
  """
  def visit_sessions(grouped_query) do
    from(r in grouped_query,
      where: not is_nil(r.session_id),
      having: max(r.session_page_views) > 0
    )
  end

  @doc """
  Excludes requests classified as bots at track time. Visitor metrics use this;
  server metrics (requests, errors, latency) keep bot traffic since it is real load.
  Rows tracked before bot detection (NULL or a regular device type) are kept.
  """
  def exclude_bots(query) do
    from(r in query, where: is_nil(r.device_type) or r.device_type != "bot")
  end

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
  Keeps requests that came with a referer (not NULL, blank or "Direct").
  Internal-domain filtering happens in Elixir on the parsed host.
  """
  def filter_has_referer(query) do
    from(r in query, where: r.referer != "Direct" and r.referer != "")
  end

  @doc """
  Filters query to only include static file requests (by extension).
  """
  def filter_static_files(query) do
    [first | rest] = @static

    condition =
      Enum.reduce(rest, dynamic([r], like(r.path, ^"%#{first}")), fn ext, acc ->
        dynamic([r], ^acc or like(r.path, ^"%#{ext}"))
      end)

    from(r in query, where: ^condition)
  end

  # Private helper functions

  defp exclude_static_files(query) do
    Enum.reduce(@static, query, fn ext, q ->
      from(r in q, where: not like(r.path, ^"%#{ext}"))
    end)
  end

  defp exclude_asset_paths(query) do
    Enum.reduce(@paths, query, fn path, q ->
      from(r in q, where: not like(r.path, ^"#{path}%"))
    end)
  end

  defp exclude_dev_paths(query) do
    Enum.reduce(@dev, query, fn path, q ->
      from(r in q, where: not like(r.path, ^"#{path}%"))
    end)
  end

  defp filter_from_date(query, nil), do: query

  defp filter_from_date(query, from_date),
    do: from(r in query, where: r.inserted_at >= ^start_of(from_date))

  defp filter_to_date(query, nil), do: query

  defp filter_to_date(query, to_date),
    do: from(r in query, where: r.inserted_at <= ^end_of(to_date))

  @doc """
  Converts a range start (`Date`, `NaiveDateTime` or ISO string) to a `NaiveDateTime`.
  Dates start at 00:00:00.
  """
  def start_of(value), do: to_naive(value, ~T[00:00:00])

  @doc """
  Converts a range end (`Date`, `NaiveDateTime` or ISO string) to a `NaiveDateTime`.
  Dates end at 23:59:59.
  """
  def end_of(value), do: to_naive(value, ~T[23:59:59])

  defp to_naive(%Date{} = date, time), do: NaiveDateTime.new!(date, time)
  defp to_naive(%NaiveDateTime{} = datetime, _time), do: datetime

  defp to_naive(string, time) when is_binary(string) do
    case NaiveDateTime.from_iso8601(string) do
      {:ok, datetime} ->
        datetime

      {:error, _} ->
        case Date.from_iso8601(String.slice(string, 0, 10)) do
          {:ok, date} -> NaiveDateTime.new!(date, time)
          {:error, _} -> string
        end
    end
  end

  defp to_naive(other, _time), do: other
end
