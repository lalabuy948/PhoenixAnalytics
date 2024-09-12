defmodule PhoenixAnalytics.Repo.Migrations.CreateRequests do
  use Ecto.Migration

  def change do
    create table(:requests) do
      add(:request_id, :binary_id)
      add(:method, :string)
      add(:path, :string)
      add(:status_code, :integer)
      add(:duration_ms, :float)
      add(:user_agent, :string)
      add(:remote_ip, :string)
      add(:referer, :string)
      add(:device, :string)
      add(:session_id, :binary_id)
      add(:session_page_views, :integer)

      timestamps(inserted_at: :inserted_at, updated_at: false)
    end
  end
end
