defmodule JikanWeb.TimeEntryLive.FormTimezoneTest do
  use JikanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jikan.TrackingFixtures
  import Jikan.AccountsFixtures

  alias Jikan.Tracking

  describe "Timezone conversion in Time Entry forms" do
    setup %{conn: conn} do
      user = user_fixture()
      client = client_fixture(user)
      project = project_fixture(user, %{client_id: client.id, color: "#3B82F6"})
      
      %{user: user, client: client, project: project, conn: log_in_user(conn, user)}
    end

    test "new time entry: enter CET time, save as UTC, display as CET", %{conn: conn, project: project} do
      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Enter time in CET timezone - user expects this to be local time
      cet_time = "07:00"
      form_data = %{
        project_id: to_string(project.id),  # Convert to string as expected by form
        date: "2026-03-13", # Winter date (CET = UTC+1)
        start_time: cet_time,
        end_time: "15:00", # Also CET
        duration_minutes: 480,
        description: "Test timezone conversion",
        billable: true
      }

      # Submit the form
      {:ok, _live, _html} = 
        live
        |> form("#time_entry-form", time_entry: form_data)
        |> render_submit()
        |> follow_redirect(conn, ~p"/time-entries")

      # Get the created time entry from database
      time_entry = Tracking.list_time_entries(conn.assigns.current_user) |> List.first()
      
      # Verify times are stored in UTC (07:00 CET = 06:00 UTC)
      assert time_entry.start_time == ~T[06:00:00]
      assert time_entry.end_time == ~T[14:00:00] # 15:00 CET = 14:00 UTC

      # Now edit the same entry and verify it displays in CET
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      
      # Check that form displays times in local timezone (CET)
      html = render(edit_live)
      assert html =~ "value=\"07:00:00\""  # start_time displayed as CET
      assert html =~ "value=\"15:00:00\""  # end_time displayed as CET
    end

    test "edit historical time entry: displays times in CET regardless of creation date", %{conn: conn, project: project, user: user} do
      # Create a time entry with specific UTC times as if it was created before timezone fix
      historical_date = ~D[2026-01-15]
      {:ok, time_entry} = Tracking.create_time_entry(user, %{
        project_id: project.id,
        date: historical_date,
        start_time: ~T[08:00:00], # UTC time
        end_time: ~T[16:00:00],   # UTC time  
        duration_minutes: 480,
        description: "Historical entry",
        billable: true
      })

      # Edit the historical entry
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      
      # Should display times converted to CET (08:00 UTC = 09:00 CET in winter)
      html = render(edit_live)
      assert html =~ "value=\"09:00:00\""  # 08:00 UTC + 1 hour (CET) = 09:00
      assert html =~ "value=\"17:00:00\""  # 16:00 UTC + 1 hour (CET) = 17:00
    end

    test "edit recent time entry: displays times in CET for newly created entries", %{conn: conn, project: project, user: user} do
      # Create a time entry as if created after timezone fix with proper UTC storage
      recent_date = ~D[2026-03-13] 
      {:ok, time_entry} = Tracking.create_time_entry(user, %{
        project_id: project.id,
        date: recent_date,
        start_time: ~T[06:00:00], # Already properly stored as UTC
        end_time: ~T[14:00:00],   # Already properly stored as UTC
        duration_minutes: 480,
        description: "Recent entry", 
        billable: true
      })

      # Edit the recent entry  
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      
      # Should display times converted to CET (06:00 UTC = 07:00 CET)
      html = render(edit_live)
      assert html =~ "value=\"07:00:00\""  # 06:00 UTC + 1 hour (CET) = 07:00
      assert html =~ "value=\"15:00:00\""  # 14:00 UTC + 1 hour (CET) = 15:00
    end

    test "midnight edge case: handles timezone conversion across day boundaries", %{conn: conn, project: project} do
      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Enter midnight time in CET - should convert to 23:00 UTC previous day
      form_data = %{
        project_id: project.id,
        date: "2026-03-13",
        start_time: "00:30", # 00:30 CET
        end_time: "08:30",   # 08:30 CET
        duration_minutes: 480,
        description: "Midnight test",
        billable: true
      }

      # Submit the form
      {:ok, _live, _html} = 
        live
        |> form("#time_entry-form", time_entry: form_data)
        |> render_submit()
        |> follow_redirect(conn, ~p"/time-entries")

      # Get the created time entry
      time_entry = Tracking.list_time_entries(conn.assigns.current_user) |> List.first()
      
      # Verify times are stored in UTC
      assert time_entry.start_time == ~T[23:30:00] # 00:30 CET = 23:30 UTC (previous day)
      assert time_entry.end_time == ~T[07:30:00]   # 08:30 CET = 07:30 UTC

      # Edit and verify it displays back as CET
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      html = render(edit_live)
      assert html =~ "value=\"00:30:00\""  # Should display original CET time
      assert html =~ "value=\"08:30:00\""  # Should display original CET time
    end

    test "summer time (CEST): handles DST timezone conversion correctly", %{conn: conn, project: project} do
      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Use a summer date when Berlin is CEST (UTC+2)
      form_data = %{
        project_id: project.id,
        date: "2026-07-15", # Summer date (CEST = UTC+2)
        start_time: "09:00", # 09:00 CEST
        end_time: "17:00",   # 17:00 CEST  
        duration_minutes: 480,
        description: "Summer time test",
        billable: true
      }

      # Submit the form
      {:ok, _live, _html} = 
        live
        |> form("#time_entry-form", time_entry: form_data)
        |> render_submit()
        |> follow_redirect(conn, ~p"/time-entries")

      # Get the created time entry
      time_entry = Tracking.list_time_entries(conn.assigns.current_user) |> List.first()
      
      # Verify times are stored in UTC (subtract 2 hours for CEST)
      assert time_entry.start_time == ~T[07:00:00] # 09:00 CEST - 2 hours = 07:00 UTC
      assert time_entry.end_time == ~T[15:00:00]   # 17:00 CEST - 2 hours = 15:00 UTC

      # Edit and verify it displays back as CEST
      {:ok, edit_live, _html} = live(conn, ~p"/time-entries/#{time_entry.id}/edit")
      html = render(edit_live)
      assert html =~ "value=\"09:00:00\""  # Should display original CEST time
      assert html =~ "value=\"17:00:00\""  # Should display original CEST time
    end

    test "form validation with timezone conversion", %{conn: conn, project: project} do
      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Submit invalid form with timezone-aware times
      invalid_data = %{
        project_id: project.id,
        date: "2026-03-13",
        start_time: "08:00", # CET time
        end_time: "07:00",   # Earlier end time (invalid)
        duration_minutes: "", # Missing duration 
        description: "",     # Missing description
        billable: true
      }

      # Form should validate and show errors, but still preserve timezone conversion
      html = 
        live
        |> form("#time_entry-form", time_entry: invalid_data)
        |> render_change()

      # Should show validation errors
      assert html =~ "can&#39;t be blank"
      
      # But times should still be displayed correctly (not converted to UTC)
      assert html =~ "value=\"08:00:00\""  # start_time preserved as CET
      assert html =~ "value=\"07:00:00\""  # end_time preserved as CET
    end

    test "Update Rate & Total button with timezone conversion", %{conn: conn, user: user} do
      # Create a client and project with hourly rates
      client = client_fixture(user, %{default_hourly_rate: Decimal.new("500.00")})
      project = project_fixture(user, %{client_id: client.id, hourly_rate: Decimal.new("600.00"), color: "#10B981"})

      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Fill form with CET times
      form_data = %{
        project_id: project.id,
        date: "2026-03-13",
        start_time: "09:00", # CET
        end_time: "17:00",   # CET (8 hours)
        duration_minutes: 480, # 8 hours
        description: "Rate test",
        billable: true
      }

      # Fill form
      live
      |> form("#time_entry-form", time_entry: form_data)
      |> render_change()

      # Click "Update Rate & Total" button
      html = live |> element("button", "Update Rate & Total") |> render_click()

      # Should calculate total correctly despite timezone conversion
      # 8 hours * 600 DKK/hour = 4800 DKK
      assert html =~ "DKK 4800.00"

      # Times should still be displayed in CET
      assert html =~ "value=\"09:00:00\""
      assert html =~ "value=\"17:00:00\""
    end

    test "handles nil times gracefully during conversion", %{conn: conn, project: project} do
      {:ok, live, _html} = live(conn, ~p"/time-entries/new")

      # Submit form with only duration, no start/end times
      form_data = %{
        project_id: project.id,
        date: "2026-03-13", 
        start_time: "",  # Empty
        end_time: "",    # Empty
        duration_minutes: 240, # 4 hours
        description: "Duration only",
        billable: true
      }

      # Should create successfully without timezone conversion issues
      {:ok, _live, _html} = 
        live
        |> form("#time_entry-form", time_entry: form_data)
        |> render_submit()
        |> follow_redirect(conn, ~p"/time-entries")

      # Get the created time entry
      time_entry = Tracking.list_time_entries(conn.assigns.current_user) |> List.first()
      
      # Should have nil times and only duration
      assert time_entry.start_time == nil
      assert time_entry.end_time == nil
      assert time_entry.duration_minutes == 240
    end
  end

  # Note: Private timezone conversion functions are tested indirectly through the LiveView integration tests above.
  # The behavior is verified by checking that times entered in CET are saved as UTC and displayed back as CET.
end