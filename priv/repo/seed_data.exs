defmodule SeedData do
  alias PhoenixAnalytics.Services.Utility
  @methods ["GET", "POST", "PUT", "DELETE"]
  @paths [
    "/",
    "/home",
    "/login",
    "/update-profile",
    "/contact",
    "/about",
    "/assets/app.css",
    "/assets/app.js"
  ]
  @user_agents [
    "Mozilla/5.0 (Linux; U; Android 9; en-us; SM-J337A Build/PPR1.180610.011) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.90 Mobile Safari/537.36",
    "Mozilla/5.0 (Linux; Android 11; SM-G960F Build/RP1A.200720.012) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (iPad; CPU OS 14_4_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15",
    "Mozilla/5.0 (Linux; U; Android 8.1.0; en-us; Redmi Note 5 Build/OPM1.171019.011) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Mobile Safari/537.36",
    "Mozilla/5.0 (Linux; Android 9; Pixel 2 Build/PQ3A.190801.002) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Mobile Safari/537.36",
    "Mozilla/5.0 (iPad; CPU OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:78.0) Gecko/20100101 Firefox/78.0",
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/16B92 Safari/605.1.15",
    "Mozilla/5.0 (Linux; Android 10; SM-G981U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Mobile Safari/537.36",
    "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko",
    "Mozilla/5.0 (Linux; Android 8.0.0; SM-G935V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Mobile Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
    "Mozilla/5.0 (Linux; Android 11; SM-G970F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
    "Mozilla/5.0 (Linux; Android 10; SM-G965U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Mobile Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; Trident/7.0; AS; rv:11.0) like Gecko",
    "Mozilla/5.0 (Linux; Android 9; SAMSUNG SM-A705FN Build/PPR1.180610.011) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.75 Mobile Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15",
    "Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.96 Safari/537.36",
    "Mozilla/5.0 (Linux; Android 9; SM-J737T1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Mobile Safari/537.36",
    "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.1 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/603.3.8 (KHTML, like Gecko) Version/10.1.2 Safari/603.3.8",
    "Mozilla/5.0 (Linux; U; Android 10; en-US; SM-G973U Build/QP1A.190711.020) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Mobile Safari/537.36"
  ]

  @referers [
    "https://example.com",
    "https://example.com/login",
    "https://example.com/profile"
  ]

  def generate_request_data do
    %PhoenixAnalytics.Entities.RequestLog{
      request_id: UUID.uuid4(),
      method: Enum.random(@methods),
      path: Enum.random(@paths),
      status_code: Enum.random([200, 201, 400, 401, 403, 404, 500, 301, 302]),
      duration_ms: :rand.uniform(486) + 15,
      user_agent: Enum.random(@user_agents),
      remote_ip: Enum.random(generate_random_ips()),
      referer: Enum.random(@referers),
      device_type: Utility.get_device_type(Enum.random(@user_agents)),
      session_id: UUID.uuid4(),
      session_page_views: if(:rand.uniform() < 0.9, do: 1, else: :rand.uniform(5) + 1),
      inserted_at: random_inserted_at()
    }
  end

  defp generate_random_ips do
    for _ <- 1..10 do
      "#{:rand.uniform(255)}.#{:rand.uniform(255)}.#{:rand.uniform(255)}.#{:rand.uniform(255)}"
    end
  end

  defp get_device_type(agent_string) do
    cond do
      String.contains?(agent_string, "Mobile") -> "mobile"
      String.contains?(agent_string, "Pad") -> "tablet"
      true -> "desktop"
    end
  end

  defp random_inserted_at do
    random_seconds = :rand.uniform(360 * 24 * 60 * 60)

    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(-random_seconds, :second)
    |> NaiveDateTime.truncate(:millisecond)
    |> NaiveDateTime.to_string()
    |> String.replace("T", " ")
  end

  def prepare_values(request_data) do
    values = [
      UUID.uuid4(),
      request_data.method,
      request_data.path,
      request_data.status_code,
      request_data.duration_ms,
      request_data.user_agent,
      request_data.remote_ip,
      request_data.referer,
      get_device_type(request_data.user_agent),
      request_data.session_id,
      request_data.session_page_views,
      random_inserted_at()
    ]

    values
  end
end
