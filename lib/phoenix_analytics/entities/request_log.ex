defmodule PhoenixAnalytics.Entities.RequestLog do
  @moduledoc """
  Represents a log entry for an HTTP request.

  This Ecto schema contains various details about an HTTP request, including its
  unique identifier, method, path, status code, duration, and other metadata.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:request_id, :string, autogenerate: false}
  @timestamps_opts [type: :naive_datetime, inserted_at: :inserted_at, updated_at: false]

  schema "requests" do
    field :method, :string
    field :path, :string
    field :status_code, :integer
    field :duration_ms, :integer
    field :user_agent, :string
    field :remote_ip, :string
    field :referer, :string
    field :device_type, :string
    field :session_id, :string
    field :session_page_views, :integer

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  @doc """
  Creates a changeset for RequestLog.
  """
  def changeset(request_log, attrs) do
    request_log
    |> cast(attrs, [:request_id, :method, :path, :status_code, :duration_ms, :user_agent, :remote_ip, :referer, :device_type, :session_id, :session_page_views, :inserted_at])
    |> validate_required([:request_id, :method, :path, :status_code, :duration_ms])
    |> validate_inclusion(:status_code, 100..599)
    |> validate_number(:duration_ms, greater_than_or_equal_to: 0)
  end

  @typedoc "Unique identifier for the request"
  @type request_id :: String.t()

  @typedoc "HTTP method of the request"
  @type method :: String.t()

  @typedoc "Path of the request"
  @type path :: String.t()

  @typedoc "HTTP status code of the response"
  @type status_code :: non_neg_integer()

  @typedoc "Duration of the request in milliseconds"
  @type duration_ms :: integer()

  @typedoc "User agent string of the client"
  @type user_agent :: String.t() | nil

  @typedoc "IP address of the client"
  @type remote_ip :: String.t() | nil

  @typedoc "Referer URL of the request"
  @type referer :: String.t() | nil

  @typedoc "Type of device_type used for the request"
  @type device_type :: String.t() | nil

  @typedoc "Unique identifier for the session"
  @type session_id :: String.t() | nil

  @typedoc "Number of page views in the session"
  @type session_page_views :: non_neg_integer() | nil

  @typedoc "Timestamp when the log entry was inserted"
  @type inserted_at :: NaiveDateTime.t() | nil

  @type t :: %__MODULE__{
          request_id: request_id(),
          method: method(),
          path: path(),
          status_code: status_code(),
          duration_ms: duration_ms(),
          user_agent: user_agent(),
          remote_ip: remote_ip(),
          referer: referer(),
          device_type: device_type(),
          session_id: session_id(),
          session_page_views: session_page_views(),
          inserted_at: inserted_at()
        }
end
