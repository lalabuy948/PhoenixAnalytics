defmodule PhoenixAnalytics.Plugs.RequestTracker do
  @moduledoc """
  A Plug module for tracking and logging HTTP requests in a Phoenix application.

  This module provides functionality to:
  - Measure the duration of each request
  - Collect relevant request data (method, path, status code, etc.)
  - Track session information
  - Validate data using Ecto changesets
  - Asynchronously broadcast the collected data using PubSub

  Key components:

  - `call/2`: The main plug function that wraps the request, measures its duration, and manages session tracking
  - `prepare_request_data/4`: Prepares request data for changeset validation
  - `create_request_log/1`: Creates a validated RequestLog using changesets
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
  All data is validated using Ecto changesets before broadcasting.
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
  2. Registers a before_send callback to:
     - Create or refresh the session cookie and bump the page view counter for HTML responses.
     - Calculate the request duration.
     - Prepare request data and validate it using changesets.
     - Asynchronously broadcast the validated data using PubSub.

  The function silently catches and ignores any errors during data preparation,
  validation, or broadcasting to ensure the request processing continues unaffected
  and user applications are never impacted by tracking failures.

  ## Parameters

  - `conn`: The `Plug.Conn` struct representing the current connection.
  - `_opts`: Options passed to the plug (unused in this implementation).

  ## Returns

  Returns the `conn` struct, potentially modified by subsequent plugs or handlers.
  """
  def call(conn, _opts) do
    start_time = System.monotonic_time(:millisecond)

    Plug.Conn.register_before_send(conn, fn conn ->
      try do
        track(conn, start_time)
      rescue
        # Silently ignore all errors to ensure user applications are never affected
        _error -> conn
      end
    end)
  end

  defp track(conn, start_time) do
    conn = fetch_cookies(conn)
    session_id = conn.cookies["pa_session_id"] || generate_uuid()
    page_views = String.to_integer(conn.cookies["pa_page_views"] || "0")
    # Only HTML responses count as page views; assets, API calls etc. still belong to the session
    page_views = if html_response?(conn), do: page_views + 1, else: page_views

    user_agent = get_header(conn, "user-agent", nil)

    request_data = %{
      request_id: generate_uuid(),
      method: conn.method,
      path: conn.request_path,
      status_code: conn.status,
      duration_ms: System.monotonic_time(:millisecond) - start_time,
      user_agent: user_agent,
      remote_ip: format_ip(remote_ip(conn)),
      referer: get_header(conn, "referer", "Direct"),
      device_type: Utility.get_device_type(user_agent),
      session_id: session_id,
      session_page_views: page_views,
      inserted_at: Utility.inserted_at()
    }

    case create_request_log(request_data) do
      {:ok, request_log} -> PubSub.broadcast(request_log)
      # Silently ignore validation errors to not affect user applications
      {:error, _changeset} -> :ok
    end

    conn
    |> put_resp_cookie("pa_session_id", session_id, max_age: @five_min, same_site: "Lax")
    |> put_resp_cookie("pa_page_views", Integer.to_string(page_views),
      max_age: @five_min,
      same_site: "Lax"
    )
  end

  defp html_response?(conn) do
    conn
    |> get_resp_header("content-type")
    |> List.first("")
    |> String.starts_with?("text/html")
  end

  # Creates a validated RequestLog struct using Ecto changesets.
  # Takes raw request data and validates it using the RequestLog changeset.
  # Returns {:ok, request_log} on success, {:error, changeset} on failure.
  defp create_request_log(attrs) do
    changeset = RequestLog.changeset(%RequestLog{}, attrs)

    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end

  defp generate_uuid, do: Utility.uuid()

  # 2^32 buckets: with 1M, collisions made new visitors look like returning ones
  defp hash_ip(ip), do: :erlang.phash2(ip, 4_294_967_296) |> Integer.to_string()

  defp format_ip(ip), do: hash_ip(ip)

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
