defmodule DuckPostgres.Repo.Migrations.AddRequestsTable do
  use Ecto.Migration

  def change do
    create table(:requests) do
      add(:request_id, :binary_id)
      add(:method, :string)
      add(:path, :string)
      add(:status_code, :integer)
      add(:duration_ms, :integer)
      add(:user_agent, :string)
      add(:remote_ip, :string)
      add(:referer, :string)
      add(:device_type, :string)
      add(:session_id, :binary_id)
      add(:session_page_views, :integer)
      add(:inserted_at, :string)
    end
  end
end
