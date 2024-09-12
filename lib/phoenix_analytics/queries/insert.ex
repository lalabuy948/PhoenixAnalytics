defmodule PhoenixAnalytics.Queries.Insert do
  @moduledoc false

  alias PhoenixAnalytics.Queries.Table
  alias PhoenixAnalytics.Entities.RequestLog

  @table Table.name()
  @columns ~w(request_id method path status_code duration_ms user_agent remote_ip referer device session_id session_page_views inserted_at)
  @placeholders List.duplicate("?", length(@columns)) |> Enum.join(", ")
  @query "INSERT INTO #{@table} (#{Enum.join(@columns, ", ")}) VALUES (#{@placeholders});"

  @spec insert_one(RequestLog.t()) :: {String.t(), list()}
  def insert_one(%RequestLog{} = request_data) do
    {@query, prepare_values(request_data)}
  end

  def insert_one_query, do: @query

  @spec prepare_values(RequestLog.t()) :: list()
  defp prepare_values(%RequestLog{} = request_data) do
    [
      request_data.request_id,
      request_data.method,
      request_data.path,
      request_data.status_code,
      request_data.duration_ms,
      request_data.user_agent,
      request_data.remote_ip,
      request_data.referer,
      request_data.device_type,
      request_data.session_id,
      request_data.session_page_views,
      request_data.inserted_at
    ]
  end
end
