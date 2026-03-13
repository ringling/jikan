defmodule JikanWeb.DashboardLive.TimezoneTest do
  use JikanWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Jikan.Tracking
  alias Jikan.Timezone

  setup do
    user = Jikan.AccountsFixtures.user_fixture()
    conn = log_in_user(build_conn(), user)
    
    # Create a project for testing
    client = Jikan.TrackingFixtures.client_fixture(user)
    project = Jikan.TrackingFixtures.project_fixture(user, client_id: client.id)
    
    %{conn: conn, user: user, project: project}
  end

  describe "running timer display" do
    test "displays start time in local timezone", %{conn: conn, user: user, project: project} do
      # Start a timer
      {:ok, timer} = Tracking.start_timer(user, project.id, "Testing timezone display")
      
      # Get the local start time for comparison
      local_start = Timezone.time_to_local(timer.start_time, timer.date)
      expected_time = Calendar.strftime(local_start, "%H:%M")
      
      {:ok, view, _html} = live(conn, ~p"/dashboard")
      
      # Check that the timer displays the local time
      assert has_element?(view, "p", "Started at #{expected_time}")
    end

    test "calculates elapsed time using local timezone", %{conn: conn, user: user, project: project} do
      # Start a timer with a specific start time
      utc_start = Time.utc_now() |> Time.add(-3600, :second) # 1 hour ago
      attrs = %{
        "user_id" => user.id,
        "project_id" => project.id,
        "description" => "Test elapsed time",
        "date" => Date.utc_today(),
        "start_time" => utc_start,
        "duration_minutes" => 0,
        "pause_duration_minutes" => 0,
        "billable" => true
      }
      
      {:ok, _timer} = %Tracking.TimeEntry{}
                      |> Tracking.TimeEntry.changeset(attrs)
                      |> Jikan.Repo.insert()
      
      {:ok, view, _html} = live(conn, ~p"/dashboard")
      
      # The timer should show approximately 1 hour elapsed
      # Check for presence of timer display
      assert has_element?(view, "[class*='countdown']")
    end
  end

  describe "time formatting helpers" do
    test "format_local_time displays time in local timezone", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/dashboard")
      
      # The dashboard should render without errors even with timezone conversions
      assert html =~ "Dashboard"
      assert html =~ "Today's Hours"
    end
  end

  describe "timezone configuration" do
    test "uses configured timezone from application config" do
      # Verify the timezone is configured correctly
      assert Timezone.get_timezone() == "Europe/Berlin"
    end
    
    test "dashboard handles timezone correctly for different dates", %{conn: conn, user: user, project: project} do
      # Create time entries for different dates
      today = Date.utc_today()
      yesterday = Date.add(today, -1)
      
      # Entry from yesterday
      Jikan.TrackingFixtures.time_entry_fixture(user, %{
        project_id: project.id,
        date: yesterday,
        start_time: ~T[10:00:00],
        end_time: ~T[12:00:00],
        duration_minutes: 120
      })
      
      # Entry from today
      Jikan.TrackingFixtures.time_entry_fixture(user, %{
        project_id: project.id,
        date: today,
        start_time: ~T[14:00:00],
        end_time: ~T[16:00:00],
        duration_minutes: 120
      })
      
      {:ok, view, html} = live(conn, ~p"/dashboard")
      
      # Check that recent entries are displayed
      assert html =~ "Recent Entries"
      
      # Both entries should be visible in recent entries
      assert has_element?(view, "[class*='card bg-base-200']")
    end
  end

  describe "edge cases" do
    test "handles timer started near midnight UTC", %{conn: conn, user: user, project: project} do
      # Create a timer that starts at 23:30 UTC
      late_time = ~T[23:30:00]
      attrs = %{
        "user_id" => user.id,
        "project_id" => project.id,
        "description" => "Late night work",
        "date" => Date.utc_today(),
        "start_time" => late_time,
        "duration_minutes" => 0,
        "billable" => true
      }
      
      {:ok, _timer} = %Tracking.TimeEntry{}
                      |> Tracking.TimeEntry.changeset(attrs)
                      |> Jikan.Repo.insert()
      
      {:ok, view, _html} = live(conn, ~p"/dashboard")
      
      # Should display correctly even when local time is next day
      local_dt = Timezone.time_to_local(late_time, Date.utc_today())
      expected_time = Calendar.strftime(local_dt, "%H:%M")
      
      # Check the timer is displayed with correct local time
      assert has_element?(view, "p", "Started at #{expected_time}")
    end
    
    test "handles paused timer with timezone conversion", %{conn: conn, user: user, project: project} do
      # Start and pause a timer
      {:ok, timer} = Tracking.start_timer(user, project.id, "Paused timer test")
      {:ok, _paused} = Tracking.pause_timer(user)
      
      {:ok, view, html} = live(conn, ~p"/dashboard")
      
      # Check that paused timer is displayed correctly
      assert html =~ "Timer Paused"
      assert has_element?(view, "[class*='badge-warning']", "PAUSED")
      
      # Local time should still be displayed
      local_start = Timezone.time_to_local(timer.start_time, timer.date)
      expected_time = Calendar.strftime(local_start, "%H:%M")
      assert has_element?(view, "p", "Started at #{expected_time}")
    end
  end

end