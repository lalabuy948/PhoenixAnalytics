defmodule PhoenixAnalytics.Entities.Request do
  use Ecto.Schema
  import Ecto.Changeset

  @fields ~w(request_id method path status_code duration_ms user_agent remote_ip
    referer device session_id session_page_views inserted_at)a

  @type t :: %__MODULE__{}

  schema "requests" do
    field(:request_id, :binary_id)
    field(:method, :string)
    field(:path, :string)
    field(:status_code, :integer)
    field(:duration_ms, :integer)
    field(:user_agent, :string)
    field(:remote_ip, :string)
    field(:referer, :string)
    field(:device_type, :string)
    field(:session_id, :binary_id)
    field(:session_page_views, :integer)
    field(:inserted_at, :string)
  end

  @doc false
  def changeset(stack, attrs) do
    stack
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
