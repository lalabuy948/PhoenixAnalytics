defmodule PhoenixAnalytics.Plugs.RequestTracker do
  @moduledoc """
  A Plug module for tracking and logging HTTP requests in a Phoenix application.

  This module provides functionality to:
  - Measure the duration of each request
  - Collect relevant request data (method, path, status code, etc.)
  - Track session information
  - Asynchronously broadcast the collected data using PubSub

  Key components:

  - `call/2`: The main plug function that wraps the request, measures its duration, and manages session tracking
  - `prepare_request_data/4`: Prepares a `RequestLog` struct with relevant request and session information
  - `format_ip/1`: Formats IP addresses to string representation
  - `remote_ip/1`: Extracts the remote IP address from the connection, considering X-Forwarded-For headers
  - `get_header/3`: Safely retrieves a header value from the connection
  - `generate_uuid/0`: Generates a unique identifier for new sessions

  Usage:
  Add this plug to your endpoint straight after static plugs or router to start tracking requests:

      plug PhoenixAnalytics.Plugs.RequestTracker

  Using it in directly in router possible as well, but than you won't be able to track static files.

      pipeline :browser do
        ...
        plug PhoenixAnalytics.Plugs.RequestTracker
      end

  Note: This module uses the `PhoenixAnalytics.Services.PubSub` module to broadcast
  request data, allowing for distributed apps share requests and analysis.
  """

  import Plug.Conn

  alias PhoenixAnalytics.Services.PubSub
  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Services.Utility

  @five_min 300

  @doc false
  def init(default), do: default

  @doc """
  Main plug function that wraps the request, measures its duration, and manages session tracking.

  This function:
  1. Records the start time of the request.
  2. Manages session tracking by creating or retrieving a session ID and start time.
  3. Registers a before_send callback to:
     - Calculate the request duration and session duration.
     - Prepare request and session data.
     - Asynchronously broadcast the data using PubSub.

  The function catches any errors during data preparation or broadcasting to ensure
  the request processing continues even if tracking fails.

  ## Parameters

  - `conn`: The `Plug.Conn` struct representing the current connection.
  - `_opts`: Options passed to the plug (unused in this implementation).

  ## Returns

  Returns the `conn` struct, potentially modified by subsequent plugs or handlers.
  """
  def call(conn, _opts) do
    start_time = System.monotonic_time(:millisecond)

    conn = fetch_cookies(conn)
    session_id = conn.cookies["pa_session_id"] || generate_uuid()
    page_views = String.to_integer(conn.cookies["pa_page_views"] || "0")

    conn
    |> put_resp_cookie("pa_session_id", session_id, max_age: @five_min, same_site: "Lax")
    |> put_resp_cookie("pa_page_views", Integer.to_string(page_views + 1),
      max_age: @five_min,
      same_site: "Lax"
    )
    |> Plug.Conn.register_before_send(fn conn ->
      end_time = System.monotonic_time(:millisecond)
      page_views = String.to_integer(conn.cookies["pa_page_views"] || "0")
      request_duration = end_time - start_time

      user_agent = get_header(conn, "user-agent", "unknown")

      %RequestLog{
        request_id: generate_uuid(),
        method: Map.get(conn, :method, "unknown"),
        path: Map.get(conn, :request_path, "unknown"),
        status_code: Map.get(conn, :status, 500),
        duration_ms: request_duration,
        user_agent: user_agent,
        remote_ip: format_ip(remote_ip(conn)),
        referer: get_header(conn, "referer", "Direct"),
        device_type: Utility.get_device_type(user_agent),
        session_id: conn.cookies["pa_session_id"] || nil,
        session_page_views: page_views,
        inserted_at: Utility.inserted_at()
      }
      |> PubSub.broadcast()

      conn
    end)
  end

  defp generate_uuid, do: Utility.uuid()

  defp hash_ip(ip), do: :erlang.phash2(ip, 1_000_000) |> Integer.to_string()

  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}" |> hash_ip
  defp format_ip(ip), do: to_string(ip) |> hash_ip

  defp remote_ip(conn = %Plug.Conn{}) do
    remote_ip =
      case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
        [x_forwarded_for | _] ->
          x_forwarded_for |> String.split(",", parts: 2) |> List.first()

        [] ->
          case :inet.ntoa(conn.remote_ip) do
            {:error, _} -> ""
            address -> to_string(address)
          end
      end

    String.trim(remote_ip)
  end

  defp get_header(conn, header, default) do
    conn
    |> get_req_header(header)
    |> List.first()
    |> case do
      nil -> default
      value -> value
    end
  end
end
