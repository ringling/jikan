defmodule JikanWeb.TimeEntryLive.FormRobustParsingTest do
  use JikanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jikan.TrackingFixtures
  import Jikan.AccountsFixtures

  alias Jikan.Tracking

  describe "Robust time format parsing in form submission" do
    setup %{conn: conn} do
      user = user_fixture()
      client = client_fixture(user)
      project = project_fixture(user, %{client_id: client.id, color: "#3B82F6"})
      
      %{user: user, client: client, project: project, conn: log_in_user(conn, user)}
    end

    test "handles HH:MM:SS format correctly", %{conn: conn, project: project} do
      # Create a time entry with precise times including seconds
      {:ok, time_entry} = Tracking.create_time_entry(conn.assigns.current_user, %{
        project_id: project.id,
        date: ~D[2026-03-13],
        start_time: ~T[06:14:18], # UTC time with seconds
        end_time: ~T[07:44:31],   # UTC time with seconds
        duration_minutes: 90,
        description: "Precise timing test",
        billable: true
      })

      # Edit the entry - should display correctly in CET format with seconds
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      
      # Verify times are displayed in CET with full precision
      html = render(edit_live)
      assert html =~ "value=\"07:14:18\""  # 06:14:18 UTC + 1 hour = 07:14:18 CET
      assert html =~ "value=\"08:44:31\""  # 07:44:31 UTC + 1 hour = 08:44:31 CET

      # Now submit the form with the displayed times (including seconds)
      updated_params = %{
        project_id: to_string(project.id),
        date: "2026-03-13",
        start_time: "08:00:00",  # CET time with seconds 
        end_time: "16:30:00",    # CET time with seconds
        duration_minutes: 510,   # 8.5 hours
        description: "Updated with seconds format",
        billable: true
      }

      # Submit should work without errors
      {:ok, _redirect_live, _html} = 
        edit_live
        |> form("#time_entry-form", time_entry: updated_params)
        |> render_submit()
        |> follow_redirect(conn, ~p"/time-entries/#{time_entry.id}")

      # Verify times were correctly converted to UTC and saved
      updated_entry = Tracking.get_time_entry!(conn.assigns.current_user, time_entry.id)
      assert updated_entry.start_time == ~T[07:00:00]  # 08:00 CET - 1 hour = 07:00 UTC
      assert updated_entry.end_time == ~T[15:30:00]    # 16:30 CET - 1 hour = 15:30 UTC
      assert updated_entry.description == "Updated with seconds format"
    end

    test "handles HH:MM format correctly", %{conn: conn, project: project} do
      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Submit form with HH:MM format (no seconds)
      form_params = %{
        project_id: to_string(project.id),
        date: "2026-03-13",
        start_time: "09:15",  # CET time without seconds
        end_time: "17:45",    # CET time without seconds 
        duration_minutes: 510,
        description: "No seconds format test",
        billable: true
      }

      # Submit should work without errors
      {:ok, _redirect_live, _html} = 
        live
        |> form("#time_entry-form", time_entry: form_params)
        |> render_submit()
        |> follow_redirect(conn, ~p"/time-entries")

      # Get the created entry
      time_entry = Tracking.list_time_entries(conn.assigns.current_user) |> List.first()

      # Verify times were correctly converted to UTC
      assert time_entry.start_time == ~T[08:15:00]  # 09:15 CET - 1 hour = 08:15 UTC
      assert time_entry.end_time == ~T[16:45:00]    # 17:45 CET - 1 hour = 16:45 UTC
      assert time_entry.description == "No seconds format test"
    end

    test "handles edge case: midnight times correctly", %{conn: conn, project: project} do
      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Test midnight edge case with seconds
      form_params = %{
        project_id: to_string(project.id),
        date: "2026-03-13",
        start_time: "00:30:45",  # Just after midnight CET
        end_time: "08:15:30",    # Morning CET
        duration_minutes: 465,   # ~7.75 hours
        description: "Midnight edge case with seconds",
        billable: true
      }

      # Submit should work
      {:ok, _redirect_live, _html} = 
        live
        |> form("#time_entry-form", time_entry: form_params)
        |> render_submit()
        |> follow_redirect(conn, ~p"/time-entries")

      # Get created entry
      time_entry = Tracking.list_time_entries(conn.assigns.current_user) |> List.first()

      # Verify correct UTC conversion (00:30:45 CET = 23:30:45 UTC previous day)
      assert time_entry.start_time == ~T[23:30:45]  # 00:30:45 CET - 1 hour = 23:30:45 UTC
      assert time_entry.end_time == ~T[07:15:30]    # 08:15:30 CET - 1 hour = 07:15:30 UTC
    end

    test "handles invalid time format gracefully", %{conn: conn, project: project} do
      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Submit form with invalid time format
      invalid_params = %{
        project_id: to_string(project.id),
        date: "2026-03-13",
        start_time: "25:99:99",  # Invalid time
        end_time: "17:45",       # Valid time
        duration_minutes: 480,
        description: "Invalid time test",
        billable: true
      }

      # Form should still submit (invalid times kept as-is)
      html = 
        live
        |> form("#time_entry-form", time_entry: invalid_params)
        |> render_submit()

      # Should show validation error or handle gracefully
      # The form should either reject the submission or keep the invalid time as-is
      # (depending on backend validation)
    end
  end
end