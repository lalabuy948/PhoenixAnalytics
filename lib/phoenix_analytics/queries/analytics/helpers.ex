defmodule PhoenixAnalytics.Queries.Helpers do
  @moduledoc false

  @static ~w(.js .css .png .jpg .jpeg .svg .gif .woff .woff2 .ttf .ico .txt .xml)s
  @paths ~w(/uploads/ /assets/ /images/ /css/ /js/ /fonts/ /favicon.ico)s
  @dev ~w(/phoenix/live_reload/ /dev/)s

  defp path_not_like(filter) do
    "AND path NOT LIKE '%#{filter}%'"
  end

  defp path_or_like(filter) do
    "OR path LIKE '%#{filter}%'"
  end

  def exclude_non_page() do
    (@static ++ @paths)
    |> Enum.map(fn filter -> path_not_like(filter) end)
    |> Enum.join("\n")
  end

  def inclusive_non_page() do
    (@static ++ @paths)
    |> Enum.map(fn filter -> path_or_like(filter) end)
    |> Enum.join("\n")
  end

  def exlude_dev() do
    @dev
    |> Enum.map(fn filter -> path_not_like(filter) end)
    |> Enum.join("\n")
  end

  def date_filter(from, to), do: date_from(from) <> date_to(to)

  def date_from(date), do: "\n" <> " AND inserted_at >= '#{date}'"
  def date_to(date), do: "\n" <> " AND inserted_at <= '#{date}'"
end
