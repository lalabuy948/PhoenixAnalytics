defmodule PhoenixAnalyticsTest do
  use ExUnit.Case
  doctest PhoenixAnalytics

  alias PhoenixAnalytics.Entities.RequestLog
  alias PhoenixAnalytics.Queries.Analytics

  # Test repository setup
  defmodule TestRepo do
    use Ecto.Repo,
      otp_app: :phoenix_analytics,
      adapter: Ecto.Adapters.SQLite3
  end

  setup_all do
    # Start the test repo
    config = [
      database: ":memory:",
      pool_size: 1,
      log: false
    ]

    {:ok, _} = TestRepo.start_link(config)

    # Configure the application to use our test repo
    Application.put_all_env(
      phoenix_analytics: [
        repo: TestRepo,
        app_domain: "test.com",
        cache_ttl: 0
      ]
    )

    # Create the requests table
    TestRepo.query!("""
    CREATE TABLE requests (
      request_id VARCHAR(255) PRIMARY KEY,
      method VARCHAR(10) NOT NULL,
      path TEXT NOT NULL,
      status_code INTEGER NOT NULL,
      duration_ms INTEGER NOT NULL,
      user_agent TEXT,
      remote_ip VARCHAR(45),
      referer TEXT,
      device_type VARCHAR(20),
      session_id VARCHAR(255),
      session_page_views INTEGER,
      inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)

    :ok
  end

  setup do
    # Clean the table before each test
    TestRepo.delete_all(RequestLog)
    :ok
  end

  # Test fixtures with known dates and expected counts
  defp create_test_fixtures do
    # Define specific test dates for predictable results
    today = ~N[2025-01-15 12:00:00]
    yesterday = ~N[2025-01-14 12:00:00]
    last_month = ~N[2024-12-15 12:00:00]
    last_year = ~N[2024-01-15 12:00:00]

    fixtures = [
      # Today: 3 records, 2 unique visitors, 2 sessions
      %{
        request_id: "req_today_1",
        method: "GET",
        path: "/home",
        status_code: 200,
        duration_ms: 100,
        user_agent: "Mozilla/5.0",
        remote_ip: "192.168.1.1",
        referer: "https://google.com",
        device_type: "desktop",
        session_id: "session_1",
        session_page_views: 1,
        inserted_at: today
      },
      %{
        request_id: "req_today_2",
        method: "GET",
        path: "/about",
        status_code: 200,
        duration_ms: 150,
        user_agent: "Mozilla/5.0",
        remote_ip: "192.168.1.1",
        referer: "https://google.com",
        device_type: "desktop",
        session_id: "session_1",
        session_page_views: 2,
        inserted_at: today
      },
      %{
        request_id: "req_today_3",
        method: "GET",
        path: "/contact",
        status_code: 200,
        duration_ms: 120,
        user_agent: "Safari/605.1.15",
        remote_ip: "192.168.1.2",
        referer: "https://facebook.com",
        device_type: "mobile",
        session_id: "session_2",
        session_page_views: 1,
        inserted_at: today
      },

      # Yesterday: 2 records, 1 unique visitor, 1 session
      %{
        request_id: "req_yesterday_1",
        method: "GET",
        path: "/products",
        status_code: 200,
        duration_ms: 200,
        user_agent: "Chrome/91.0",
        remote_ip: "192.168.1.3",
        referer: "https://twitter.com",
        device_type: "desktop",
        session_id: "session_3",
        session_page_views: 1,
        inserted_at: yesterday
      },
      %{
        request_id: "req_yesterday_2",
        method: "GET",
        path: "/services",
        status_code: 404,
        duration_ms: 50,
        user_agent: "Chrome/91.0",
        remote_ip: "192.168.1.3",
        referer: "https://twitter.com",
        device_type: "desktop",
        session_id: "session_3",
        session_page_views: 2,
        inserted_at: yesterday
      },

      # Last month: 1 record, 1 unique visitor, 1 session
      %{
        request_id: "req_last_month_1",
        method: "POST",
        path: "/api/users",
        status_code: 201,
        duration_ms: 300,
        user_agent: "Mozilla/5.0 (X11; Linux x86_64) Firefox/120.0",
        remote_ip: "192.168.1.4",
        referer: nil,
        device_type: "desktop",
        session_id: "session_4",
        session_page_views: 1,
        inserted_at: last_month
      },

      # Last year: 1 record, 1 unique visitor, 1 session
      %{
        request_id: "req_last_year_1",
        method: "GET",
        path: "/archive",
        status_code: 200,
        duration_ms: 80,
        user_agent: "Firefox/88.0",
        remote_ip: "192.168.1.5",
        referer: "https://github.com",
        device_type: "desktop",
        session_id: "session_5",
        session_page_views: 1,
        inserted_at: last_year
      }
    ]

    TestRepo.insert_all(RequestLog, fixtures)

    %{
      today: today,
      yesterday: yesterday,
      last_month: last_month,
      last_year: last_year,
      expected: %{
        # visits = distinct sessions
        today: %{requests: 3, unique_visitors: 2, sessions: 2, pageviews: 3, visits: 2},
        yesterday: %{requests: 2, unique_visitors: 1, sessions: 1, pageviews: 1, visits: 1},
        last_month: %{requests: 1, unique_visitors: 1, sessions: 1, pageviews: 0, visits: 1},
        last_year: %{requests: 1, unique_visitors: 1, sessions: 1, pageviews: 1, visits: 1}
      }
    }
  end

  describe "Daily Analytics Queries" do
    test "unique visitors - today vs yesterday" do
      fixtures = create_test_fixtures()

      # Test today
      today_start = NaiveDateTime.to_date(fixtures.today)
      today_end = today_start
      query = Analytics.unique_visitors(today_start, today_end)
      result = TestRepo.one(query)
      assert result == fixtures.expected.today.unique_visitors

      # Test yesterday  
      yesterday_start = NaiveDateTime.to_date(fixtures.yesterday)
      yesterday_end = yesterday_start
      query = Analytics.unique_visitors(yesterday_start, yesterday_end)
      result = TestRepo.one(query)
      assert result == fixtures.expected.yesterday.unique_visitors

      # Test empty day (should return 0)
      empty_day = ~D[2025-01-01]
      query = Analytics.unique_visitors(empty_day, empty_day)
      result = TestRepo.one(query)
      assert result == 0
    end

    test "total requests - today vs yesterday" do
      fixtures = create_test_fixtures()

      # Test today
      today_start = NaiveDateTime.to_date(fixtures.today)
      today_end = today_start
      query = Analytics.total_requests(today_start, today_end)
      result = TestRepo.one(query)
      assert result == fixtures.expected.today.requests

      # Test yesterday
      yesterday_start = NaiveDateTime.to_date(fixtures.yesterday)
      yesterday_end = yesterday_start
      query = Analytics.total_requests(yesterday_start, yesterday_end)
      result = TestRepo.one(query)
      assert result == fixtures.expected.yesterday.requests

      # Test empty day (should return 0)
      empty_day = ~D[2025-01-01]
      query = Analytics.total_requests(empty_day, empty_day)
      result = TestRepo.one(query)
      assert result == 0
    end

    test "total pageviews - today vs yesterday" do
      fixtures = create_test_fixtures()

      # Test today (3 GET requests, all successful)
      today_start = NaiveDateTime.to_date(fixtures.today)
      today_end = today_start
      query = Analytics.total_pageviews(today_start, today_end)
      result = TestRepo.one(query)
      assert result == fixtures.expected.today.pageviews

      # Test yesterday (1 successful GET, 1 404 GET - only count successful)
      yesterday_start = NaiveDateTime.to_date(fixtures.yesterday)
      yesterday_end = yesterday_start
      query = Analytics.total_pageviews(yesterday_start, yesterday_end)
      result = TestRepo.one(query)
      assert result == fixtures.expected.yesterday.pageviews

      # Test empty day (should return 0)
      empty_day = ~D[2025-01-01]
      query = Analytics.total_pageviews(empty_day, empty_day)
      result = TestRepo.one(query)
      assert result == 0
    end
  end

  describe "Time Period Analytics Queries" do
    test "visits per period - day interval" do
      fixtures = create_test_fixtures()

      # Test week range that includes our test days
      week_start = ~D[2025-01-14]
      week_end = ~D[2025-01-15]
      query = Analytics.visits_per_period(week_start, week_end, "day")
      results = TestRepo.all(query)

      # Should return data for both days
      assert length(results) == 2

      # Find results by date
      today_result = Enum.find(results, &(&1.date == "2025-01-15"))
      yesterday_result = Enum.find(results, &(&1.date == "2025-01-14"))

      assert today_result != nil
      assert today_result.visits == fixtures.expected.today.visits
      assert today_result.unique_visitors == fixtures.expected.today.unique_visitors

      assert yesterday_result != nil
      assert yesterday_result.visits == fixtures.expected.yesterday.visits
      assert yesterday_result.unique_visitors == fixtures.expected.yesterday.unique_visitors
    end

    test "visits per period - month interval" do
      fixtures = create_test_fixtures()

      # Test range that spans multiple months
      start_date = ~D[2024-12-01]
      end_date = ~D[2025-01-31]
      query = Analytics.visits_per_period(start_date, end_date, "month")
      results = TestRepo.all(query)

      # Should return data for months that have data
      assert length(results) == 2

      # Find results by month
      current_month = Enum.find(results, &(&1.date == "2025-01"))
      last_month = Enum.find(results, &(&1.date == "2024-12"))

      assert current_month != nil

      assert current_month.visits ==
               fixtures.expected.today.visits + fixtures.expected.yesterday.visits

      assert last_month != nil
      assert last_month.visits == fixtures.expected.last_month.visits
    end

    test "visits per period - year interval" do
      fixtures = create_test_fixtures()

      # Test range that spans multiple years
      start_date = ~D[2024-01-01]
      end_date = ~D[2025-12-31]
      query = Analytics.visits_per_period(start_date, end_date, "year")
      results = TestRepo.all(query)

      # Should return data for both years
      assert length(results) == 2

      # Find results by year
      current_year = Enum.find(results, &(&1.date == "2025"))
      last_year = Enum.find(results, &(&1.date == "2024"))

      assert current_year != nil

      assert current_year.visits ==
               fixtures.expected.today.visits + fixtures.expected.yesterday.visits

      assert last_year != nil

      assert last_year.visits ==
               fixtures.expected.last_month.visits + fixtures.expected.last_year.visits
    end
  end

  describe "Analytics with Zero Data" do
    test "queries return 0 for periods with no data" do
      create_test_fixtures()

      # Test completely empty date range
      empty_start = ~D[2020-01-01]
      empty_end = ~D[2020-01-31]

      # Basic stats should return 0
      assert TestRepo.one(Analytics.unique_visitors(empty_start, empty_end)) == 0
      assert TestRepo.one(Analytics.total_requests(empty_start, empty_end)) == 0
      assert TestRepo.one(Analytics.total_pageviews(empty_start, empty_end)) == 0

      # Time-based queries should return empty list (not 0 values)
      assert TestRepo.all(Analytics.visits_per_period(empty_start, empty_end, "day")) == []

      assert TestRepo.all(Analytics.total_requests_per_period(empty_start, empty_end, "day")) ==
               []
    end

    test "partial data queries handle missing periods correctly" do
      _fixtures = create_test_fixtures()

      # Test range that includes days with and without data
      # Day before yesterday (no data)
      start_date = ~D[2025-01-13]
      # Today (has data)
      end_date = ~D[2025-01-15]

      query = Analytics.visits_per_period(start_date, end_date, "day")
      results = TestRepo.all(query)

      # Should only return days that have data, not zero entries
      dates = Enum.map(results, & &1.date) |> Enum.sort()
      assert dates == ["2025-01-14", "2025-01-15"]

      # Verify counts are correct
      assert length(results) == 2
    end
  end

  describe "Popular Content Analytics" do
    test "popular pages returns correct data" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      query = Analytics.popular_pages(start_date, end_date)
      results = TestRepo.all(query)

      # Should return pages ordered by visit count 
      assert length(results) > 0

      # All results should have path and visits count
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :source)
        assert Map.has_key?(result, :visits)
        assert is_binary(result.source)
        assert is_integer(result.visits)
        assert result.visits > 0
      end)
    end

    test "status code distribution" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      query = Analytics.status_code_distribution(start_date, end_date)
      results = TestRepo.all(query)

      # Should include both 200 and 404 status codes from our fixtures
      assert length(results) >= 2

      status_codes = Enum.map(results, & &1.status_code) |> Enum.sort()
      assert 200 in status_codes
      assert 404 in status_codes
    end
  end

  describe "Performance Analytics" do
    test "average response time" do
      fixtures = create_test_fixtures()

      today_start = NaiveDateTime.to_date(fixtures.today)
      today_end = today_start

      query = Analytics.average_response_time(today_start, today_end)
      result = TestRepo.one(query)

      # Today has 3 requests: 100ms, 150ms, 120ms = avg 123.33ms
      expected_avg = (100 + 150 + 120) / 3
      assert_in_delta result, expected_avg, 0.1
    end

    test "bounce rate calculation" do
      fixtures = create_test_fixtures()

      start_date = NaiveDateTime.to_date(fixtures.today)
      end_date = start_date

      query = Analytics.bounce_rate(start_date, end_date)
      result = TestRepo.one(query)

      # Today has 2 sessions: session_1 (2 pages), session_2 (1 page)
      # Bounce rate = 1 session with 1 page / 2 total sessions = 50%
      assert Map.has_key?(result, :bounce_rate)
      assert result.bounce_rate == 50.0
    end
  end

  describe "Chart Data Analytics" do
    test "device usage analytics" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      query = Analytics.devices_usage(start_date, end_date)
      results = TestRepo.all(query)

      # Should return device types from successful non-page requests
      assert length(results) > 0

      # Verify structure and find desktop/mobile devices
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :device)
        assert Map.has_key?(result, :count)
        assert is_binary(result.device) or is_nil(result.device)
        assert is_integer(result.count)
        assert result.count > 0
      end)

      # Should include devices from our fixtures
      device_types = Enum.map(results, & &1.device)
      assert "desktop" in device_types
      assert "mobile" in device_types
    end

    test "status code distribution per period" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      # Test daily status breakdown
      query = Analytics.statuses_per_period(start_date, end_date, "day")
      results = TestRepo.all(query)

      # Two days with data
      assert length(results) == 2

      # Verify structure for status code breakdown
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :date)
        assert Map.has_key?(result, :ok_200s)
        assert Map.has_key?(result, :redirects_300s)
        assert Map.has_key?(result, :errors_400s)
        assert Map.has_key?(result, :fails_500s)

        # All should be integers
        assert is_integer(result.ok_200s)
        assert is_integer(result.errors_400s)
      end)

      # Find today's results - should have 3 successful requests
      today_result = Enum.find(results, &(&1.date == "2025-01-15"))
      assert today_result != nil
      assert today_result.ok_200s == 3
      assert today_result.errors_400s == 0

      # Find yesterday's results - should have 1 successful, 1 error
      yesterday_result = Enum.find(results, &(&1.date == "2025-01-14"))
      assert yesterday_result != nil
      assert yesterday_result.ok_200s == 1
      assert yesterday_result.errors_400s == 1
    end

    test "total requests per period" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      # Test daily requests
      query = Analytics.total_requests_per_period(start_date, end_date, "day")
      results = TestRepo.all(query)

      assert length(results) == 2

      # Verify structure
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :date)
        assert Map.has_key?(result, :hits)
        assert is_integer(result.hits)
        assert result.hits > 0
      end)

      # Verify specific counts
      today_result = Enum.find(results, &(&1.date == "2025-01-15"))
      assert today_result != nil
      assert today_result.hits == 3

      yesterday_result = Enum.find(results, &(&1.date == "2025-01-14"))
      assert yesterday_result != nil
      assert yesterday_result.hits == 2
    end

    test "slowest pages analytics" do
      create_test_fixtures()

      results = TestRepo.all(Analytics.slowest_pages(~D[2025-01-14], ~D[2025-01-15]))

      assert length(results) > 0

      for result <- results do
        assert is_binary(result.method)
        assert is_binary(result.path)
        assert result.total_ms > 0
        assert result.hits > 0
      end
    end

    test "slowest resources analytics" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      query = Analytics.slowest_resources(start_date, end_date)
      results = TestRepo.all(query)

      # May be empty since our fixtures are all page requests
      # But should return proper structure if any resources exist
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :path)
        assert Map.has_key?(result, :duration)
        assert is_binary(result.path)
        assert is_float(result.duration)
      end)
    end

    test "visits per period with different intervals" do
      create_test_fixtures()

      # Test monthly interval
      start_date = ~D[2024-12-01]
      end_date = ~D[2025-01-31]

      query = Analytics.visits_per_period(start_date, end_date, "month")
      results = TestRepo.all(query)

      # Two months with data
      assert length(results) == 2

      # Verify structure 
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :date)
        assert Map.has_key?(result, :visits)
        assert Map.has_key?(result, :unique_visitors)
        assert is_integer(result.visits)
        assert is_integer(result.unique_visitors)
      end)

      # Test yearly interval
      query = Analytics.visits_per_period(start_date, end_date, "year")
      results = TestRepo.all(query)

      # Two years with data
      assert length(results) == 2

      # Verify yearly aggregation
      current_year = Enum.find(results, &(&1.date == "2025"))
      last_year = Enum.find(results, &(&1.date == "2024"))

      assert current_year != nil
      assert last_year != nil

      # Current year should have data from today + yesterday: 2 + 1 sessions
      assert current_year.visits == 3
      assert current_year.unique_visitors >= 2
    end
  end

  describe "Period-based Limited Analytics" do
    test "unique visitors per period limited" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      query = Analytics.unique_visitors_per_period_limited(start_date, end_date)
      results = TestRepo.all(query)

      # Limited to 30 results
      assert length(results) <= 30
      # Two days with data
      assert length(results) == 2

      # Verify structure
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :date)
        assert Map.has_key?(result, :hits)
        assert is_integer(result.hits)
        assert result.hits > 0
      end)
    end

    test "total pageviews per period limited" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      query = Analytics.total_pageviews_per_period_limited(start_date, end_date)
      results = TestRepo.all(query)

      # Limited to 30 results
      assert length(results) <= 30

      # Verify structure
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :date)
        assert Map.has_key?(result, :hits)
        assert is_integer(result.hits)
        # Could be 0 for periods with no successful page views
        assert result.hits >= 0
      end)

      # Find results and verify pageview counts (only successful GET requests count)
      today_result = Enum.find(results, &(&1.date == "2025-01-15"))
      yesterday_result = Enum.find(results, &(&1.date == "2025-01-14"))

      assert today_result != nil
      # All 3 today requests are successful GET
      assert today_result.hits == 3

      assert yesterday_result != nil
      # Only 1 successful GET yesterday (1 is 404)
      assert yesterday_result.hits == 1
    end

    test "total requests per period limited" do
      create_test_fixtures()

      start_date = ~D[2025-01-14]
      end_date = ~D[2025-01-15]

      query = Analytics.total_requests_per_period_limited(start_date, end_date)
      results = TestRepo.all(query)

      # Limited to 30 results
      assert length(results) <= 30
      # Two days with data
      assert length(results) == 2

      # Verify structure
      Enum.each(results, fn result ->
        assert Map.has_key?(result, :date)
        assert Map.has_key?(result, :hits)
        assert is_integer(result.hits)
        assert result.hits > 0
      end)
    end
  end

  describe "RequestTracker plug" do
    import Plug.Test
    import Plug.Conn

    alias PhoenixAnalytics.Plugs.RequestTracker

    setup do
      PhoenixAnalytics.Services.PubSub.subscribe()
      :ok
    end

    defp track(conn, content_type) do
      conn
      |> RequestTracker.call([])
      |> put_resp_content_type(content_type)
      |> send_resp(200, "")
    end

    test "first HTML request starts a session with one page view" do
      conn = track(conn(:get, "/"), "text/html")

      assert_receive {:request_sent, log}
      assert log.session_page_views == 1
      assert log.session_id == conn.resp_cookies["pa_session_id"].value
      assert conn.resp_cookies["pa_page_views"].value == "1"
      assert log.referer == "Direct"
      assert %NaiveDateTime{} = log.inserted_at
    end

    test "non-HTML responses keep the session but do not count as page views" do
      conn =
        conn(:get, "/assets/app.js")
        |> put_req_cookie("pa_session_id", "abc")
        |> put_req_cookie("pa_page_views", "2")
        |> track("application/javascript")

      assert_receive {:request_sent, log}
      assert log.session_id == "abc"
      assert log.session_page_views == 2
      assert conn.resp_cookies["pa_page_views"].value == "2"
    end

    test "popular referers excludes Direct traffic" do
      TestRepo.insert_all(RequestLog, [
        %{
          request_id: "r1",
          method: "GET",
          path: "/",
          status_code: 200,
          duration_ms: 1,
          referer: "Direct",
          inserted_at: ~N[2025-01-15 12:00:00]
        },
        %{
          request_id: "r2",
          method: "GET",
          path: "/",
          status_code: 200,
          duration_ms: 1,
          referer: "https://google.com",
          inserted_at: ~N[2025-01-15 12:00:00]
        }
      ])

      results =
        Analytics.popular_referer(~D[2025-01-15], ~D[2025-01-15])
        |> TestRepo.all()
        |> Analytics.top_referers()

      assert Enum.map(results, & &1.source) == ["google.com"]
    end
  end

  describe "Helpers date bounds" do
    alias PhoenixAnalytics.Queries.Helpers

    test "start_of and end_of accept dates, datetimes and ISO strings" do
      assert Helpers.start_of(~D[2025-01-15]) == ~N[2025-01-15 00:00:00]
      assert Helpers.end_of(~D[2025-01-15]) == ~N[2025-01-15 23:59:59]
      assert Helpers.start_of(~N[2025-01-15 10:00:00]) == ~N[2025-01-15 10:00:00]
      assert Helpers.start_of("2025-01-15 10:00:00") == ~N[2025-01-15 10:00:00]
      assert Helpers.end_of("2025-01-15") == ~N[2025-01-15 23:59:59]
    end
  end

  describe "Bot detection" do
    alias PhoenixAnalytics.Services.Utility

    @bots [
      "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
      "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
      "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
      "Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)",
      "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.2; +https://openai.com/gptbot)",
      "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ChatGPT-User/1.0; +https://openai.com/bot",
      "DuckDuckBot-Https/1.1; (+https://duckduckgo.com/duckduckbot)",
      "Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)",
      "TelegramBot (like TwitterBot)",
      "Pingdom.com_bot_version_1.4_(http://www.pingdom.com/)",
      "Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)",
      "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)",
      "WhatsApp/2.23.20.0",
      "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)",
      "curl/8.4.0",
      "Wget/1.21.4",
      "python-requests/2.31.0",
      "python-httpx/0.27.0",
      "Go-http-client/2.0",
      "PostmanRuntime/7.36.0",
      "kube-probe/1.29",
      "ELB-HealthChecker/2.0",
      "hackney/1.20.1",
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/120.0.0.0 Safari/537.36",
      "",
      "   "
    ]

    @browsers [
      {"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
       "desktop"},
      {"Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15",
       "desktop"},
      {"Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1",
       "mobile"},
      {"Mozilla/5.0 (iPad; CPU OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1",
       "tablet"},
      {"Mozilla/5.0 (Linux; Android 13; CUBOT_X30) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
       "mobile"},
      {"Mozilla/5.0 (Linux; Android 13; SM-X700) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
       "tablet"},
      {"Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/440.0.0.30.106;FBBV/539017577]",
       "mobile"},
      {"Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 307.0.0.34.111 (iPhone14,5; iOS 17_1; en_US)",
       "mobile"},
      {"Mozilla/5.0 (Linux; Android 13; SAMSUNG SM-S911B) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/23.0 Chrome/115.0.0.0 Mobile Safari/537.36",
       "mobile"},
      {"okhttp/4.12.0", "desktop"}
    ]

    setup do
      PhoenixAnalytics.Services.PubSub.subscribe()
    end

    test "crawlers, scripts, monitors and blank user agents are bots" do
      for ua <- @bots, do: assert(Utility.get_device_type(ua) == "bot", ua)
      assert Utility.bot?(nil)
    end

    test "browsers and in-app browsers keep their device type" do
      for {ua, type} <- @browsers, do: assert(Utility.get_device_type(ua) == type, ua)
    end

    test "tracked bot requests are broadcast as bots" do
      Plug.Test.conn(:get, "/")
      |> Plug.Conn.put_req_header("user-agent", "curl/8.4.0")
      |> PhoenixAnalytics.Plugs.RequestTracker.call([])
      |> Plug.Conn.send_resp(200, "")

      assert_receive {:request_sent, %{device_type: "bot"}}
    end

    test "requests without a user agent are broadcast as bots" do
      Plug.Test.conn(:get, "/")
      |> PhoenixAnalytics.Plugs.RequestTracker.call([])
      |> Plug.Conn.send_resp(200, "")

      assert_receive {:request_sent, %{device_type: "bot", user_agent: nil}}
    end

    test "bots are excluded from visitor metrics but not server metrics" do
      base = %{method: "GET", path: "/", status_code: 200, duration_ms: 1, session_page_views: 1}

      TestRepo.insert_all(RequestLog, [
        Map.merge(base, %{
          request_id: "human",
          device_type: "desktop",
          remote_ip: "h",
          session_id: "s1",
          session_page_views: 2,
          inserted_at: ~N[2025-01-15 10:00:00]
        }),
        Map.merge(base, %{
          request_id: "legacy",
          device_type: nil,
          remote_ip: "l",
          session_id: "s2",
          session_page_views: 2,
          inserted_at: ~N[2025-01-15 10:00:00]
        }),
        Map.merge(base, %{
          request_id: "bot",
          device_type: "bot",
          remote_ip: "b",
          session_id: "s3",
          inserted_at: ~N[2025-01-15 10:00:00]
        })
      ])

      day = ~D[2025-01-15]
      assert TestRepo.one(Analytics.unique_visitors(day, day)) == 2
      assert TestRepo.one(Analytics.total_pageviews(day, day)) == 2
      assert TestRepo.one(Analytics.bounce_rate(day, day)) == %{bounce_rate: 0.0}
      assert TestRepo.one(Analytics.total_requests(day, day)) == 3

      assert "bot" in Enum.map(TestRepo.all(Analytics.devices_usage(day, day)), & &1.device)
    end
  end

  describe "Slowest endpoints" do
    alias PhoenixAnalytics.Queries.Analytics.Charts.Slowest

    defp insert_requests(requests) do
      rows =
        for {request, i} <- Enum.with_index(requests) do
          {method, path, status, duration, device} =
            if tuple_size(request) == 4, do: Tuple.insert_at(request, 4, nil), else: request

          %{
            request_id: "slow_#{i}",
            method: method,
            path: path,
            status_code: status,
            duration_ms: duration,
            device_type: device,
            inserted_at: ~N[2025-01-15 10:00:00]
          }
        end

      TestRepo.insert_all(RequestLog, rows)
    end

    defp slowest(min_samples \\ 1) do
      ~D[2025-01-15]
      |> Analytics.slowest_pages(~D[2025-01-15])
      |> TestRepo.all()
      |> Slowest.top_endpoints(min_samples)
      |> Enum.map(&Map.delete(&1, :hits))
    end

    test "separates methods on the same path and includes redirects" do
      insert_requests([
        {"GET", "/checkout", 200, 80},
        {"GET", "/checkout", 200, 120},
        {"POST", "/checkout", 302, 2000},
        {"POST", "/checkout", 500, 9000},
        {"GET", "/missing", 404, 5000}
      ])

      assert slowest() == [
               %{method: "POST", path: "/checkout", duration: 2000.0},
               %{method: "GET", path: "/checkout", duration: 100.0}
             ]
    end

    test "status 399 counts, 400 does not" do
      insert_requests([{"GET", "/a", 399, 10}, {"GET", "/b", 400, 20}])
      assert slowest() == [%{method: "GET", path: "/a", duration: 10.0}]
    end

    test "excludes assets and dev paths but keeps bots" do
      insert_requests([
        {"GET", "/app.js", 200, 900},
        {"GET", "/dev/dashboard", 200, 900},
        {"GET", "/crawled", 200, 50, "bot"},
        {"GET", "/", 200, 10}
      ])

      assert slowest() == [
               %{method: "GET", path: "/crawled", duration: 50.0},
               %{method: "GET", path: "/", duration: 10.0}
             ]
    end

    test "collapses id segments into one endpoint with a weighted average" do
      insert_requests([
        {"GET", "/users/1", 200, 100},
        {"GET", "/users/2", 200, 200},
        {"GET", "/users/2", 200, 300},
        {"GET", "/orders/0b6f3c1e-2a4d-4c8e-9f10-1a2b3c4d5e6f/items", 200, 40},
        {"GET", "/v2/report", 200, 5}
      ])

      assert slowest() == [
               %{method: "GET", path: "/users/:id", duration: 200.0},
               %{method: "GET", path: "/orders/:id/items", duration: 40.0},
               %{method: "GET", path: "/v2/report", duration: 5.0}
             ]
    end

    test "skips endpoints below the minimum sample count" do
      insert_requests([
        {"GET", "/rare", 200, 9000},
        {"GET", "/busy", 200, 100},
        {"GET", "/busy", 200, 100},
        {"GET", "/busy", 200, 100}
      ])

      assert slowest(3) == [%{method: "GET", path: "/busy", duration: 100.0}]
    end

    test "returns the top 6, ties ordered by path then method" do
      insert_requests(for path <- ~w(/g /f /e /d /c /b /a), do: {"GET", path, 200, 10})

      assert Enum.map(slowest(), & &1.path) == ~w(/a /b /c /d /e /f)
    end

    test "labels endpoints with their method, resources without" do
      alias PhoenixAnalytics.Web.Live.Components.ResChart
      assert ResChart.label(%{method: "POST", path: "/checkout"}) == "POST /checkout"
      assert ResChart.label(%{path: "/app.js"}) == "/app.js"
    end
  end

  describe "Cache" do
    alias PhoenixAnalytics.Services.Cache

    setup do
      Application.put_env(:phoenix_analytics, :cache_ttl, 60)
      on_exit(fn -> Application.put_env(:phoenix_analytics, :cache_ttl, 0) end)
    end

    test "re-raises callback errors instead of returning a Cachex error, and caches nothing" do
      key = "cache_test:#{System.unique_integer()}"

      assert_raise RuntimeError, ~r/failed/, fn -> Cache.fetch(key, fn -> raise "boom" end) end
      assert Cache.fetch(key, fn -> :computed end) == :computed
      assert Cache.fetch(key, fn -> :recomputed end) == :computed
    end
  end
end
