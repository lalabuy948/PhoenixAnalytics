defmodule PhoenixAnalytics.Queries.Table do
  @moduledoc false
  alias PhoenixAnalytics.Services.Utility

  @db_alias "postgres_db"
  @requests if Utility.mode() == :duck_postgres, do: "#{@db_alias}.requests", else: "requests"

  def name() do
    @requests
  end

  def create_requests do
    query = """
    CREATE TABLE IF NOT EXISTS #{@requests} (
      request_id UUID PRIMARY KEY,
      method VARCHAR NOT NULL,
      path VARCHAR NOT NULL,
      status_code SMALLINT NOT NULL,
      duration_ms INTEGER NOT NULL,
      user_agent VARCHAR,
      remote_ip VARCHAR,
      referer VARCHAR,
      device VARCHAR,
      session_id UUID,
      session_page_views INTEGER,
      inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """

    query
  end

  def drop_requests do
    query = "DROP TABLE IF EXISTS #{@requests};"

    query
  end

  def attach_postgres do
    postgres_conn = Application.fetch_env!(:phoenix_analytics, :postgres_conn)
    "ATTACH '#{postgres_conn}' AS #{@db_alias} (TYPE POSTGRES);"
  end
end
