defmodule PhoenixAnalytics.Entities.RequestLog do
  @moduledoc """
  Represents a log entry for an HTTP request.

  This struct contains various details about an HTTP request, including its
  unique identifier, method, path, status code, duration, and other metadata.
  """

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

  defstruct [
    :request_id,
    :method,
    :path,
    :status_code,
    :duration_ms,
    :user_agent,
    :remote_ip,
    :referer,
    :device_type,
    :session_id,
    :session_page_views,
    :inserted_at
  ]
end
