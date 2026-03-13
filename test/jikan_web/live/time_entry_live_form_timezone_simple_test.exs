defmodule JikanWeb.TimeEntryLive.FormTimezoneSimpleTest do
  use JikanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jikan.TrackingFixtures
  import Jikan.AccountsFixtures

  alias Jikan.Tracking

  describe "Timezone conversion in edit forms" do
    test "edit time entry displays UTC times converted to CET", %{conn: conn} do
      # Set up user, client and project
      user = user_fixture()
      client = client_fixture(user)
      project = project_fixture(user, %{client_id: client.id, color: "#3B82F6"})

      # Create a time entry with known UTC times
      {:ok, time_entry} = Tracking.create_time_entry(user, %{
        project_id: project.id,
        date: ~D[2026-03-13],
        start_time: ~T[06:00:00], # UTC time
        end_time: ~T[14:00:00],   # UTC time
        duration_minutes: 480,
        description: "UTC test entry",
        billable: true
      })

      # Edit the entry - this should display times in local timezone
      conn = log_in_user(conn, user)
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      
      # Verify times are displayed in CET (UTC + 1 hour)
      html = render(edit_live)
      assert html =~ "value=\"07:00:00\""  # 06:00 UTC + 1 hour = 07:00 CET
      assert html =~ "value=\"15:00:00\""  # 14:00 UTC + 1 hour = 15:00 CET
    end

    test "edit time entry with summer time displays UTC times converted to CEST", %{conn: conn} do
      # Set up user, client and project
      user = user_fixture()
      client = client_fixture(user)
      project = project_fixture(user, %{client_id: client.id, color: "#10B981"})

      # Create a time entry with known UTC times in summer
      {:ok, time_entry} = Tracking.create_time_entry(user, %{
        project_id: project.id,
        date: ~D[2026-07-15], # Summer date
        start_time: ~T[07:00:00], # UTC time
        end_time: ~T[15:00:00],   # UTC time
        duration_minutes: 480,
        description: "Summer UTC test entry",
        billable: true
      })

      # Edit the entry - this should display times in local timezone
      conn = log_in_user(conn, user)
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      
      # Verify times are displayed in CEST (UTC + 2 hours)
      html = render(edit_live)
      assert html =~ "value=\"09:00:00\""  # 07:00 UTC + 2 hours = 09:00 CEST
      assert html =~ "value=\"17:00:00\""  # 15:00 UTC + 2 hours = 17:00 CEST
    end

    test "edit time entry with nil times handles gracefully", %{conn: conn} do
      # Set up user, client and project
      user = user_fixture()
      client = client_fixture(user)
      project = project_fixture(user, %{client_id: client.id, color: "#F59E0B"})

      # Create a time entry with nil start/end times (only duration)
      {:ok, time_entry} = Tracking.create_time_entry(user, %{
        project_id: project.id,
        date: ~D[2026-03-13],
        start_time: nil,
        end_time: nil,
        duration_minutes: 240,
        description: "Duration only entry",
        billable: true
      })

      # Edit the entry - should not error with nil times
      conn = log_in_user(conn, user)
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      
      # Should render successfully without timezone conversion errors
      html = render(edit_live)
      assert html =~ "Duration only entry"
      assert html =~ "value=\"240\""  # duration_minutes
    end
  end
end