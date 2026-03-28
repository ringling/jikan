defmodule JikanWeb.ExportControllerTest do
  use JikanWeb.ConnCase

  import Jikan.AccountsFixtures
  import Jikan.TrackingFixtures

  setup %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    
    client = client_fixture(user, %{name: "Test Company"})
    project = project_fixture(user, %{
      name: "Test Project",
      client_id: client.id,
      archived: false
    })
    
    %{conn: conn, user: user, client: client, project: project}
  end

  describe "export_time_entries/2" do
    test "exports time entries as CSV with proper headers", %{conn: conn, user: user, project: project} do
      # Create test time entries
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        duration_minutes: 480,
        pause_duration_minutes: 60,
        billable: true,
        hourly_rate: Decimal.new("450.00"),
        total_amount: Decimal.new("3150.00"),  # Based on net duration (7 * 450)
        description: "Test work"
      })

      conn = get(conn, ~p"/exports/time-entries")
      
      # Check response headers
      assert ["text/csv; charset=utf-8"] = get_resp_header(conn, "content-type")
      assert [content_disposition] = get_resp_header(conn, "content-disposition")
      assert String.contains?(content_disposition, "attachment")
      assert String.contains?(content_disposition, "jikan_time_entries")
      assert String.contains?(content_disposition, ".csv")
      
      # Check CSV content
      csv_content = response(conn, 200)
      assert String.starts_with?(csv_content, "Date;Company;Project;Description")
      assert String.contains?(csv_content, "Test Company")
      assert String.contains?(csv_content, "Test Project")
      assert String.contains?(csv_content, "Test work")
    end

    test "exports with client filter", %{conn: conn, user: user, client: client, project: project} do
      # Create another client and project
      other_client = client_fixture(user, %{name: "Other Company"})
      other_project = project_fixture(user, %{
        name: "Other Project",
        client_id: other_client.id,
        archived: false
      })
      
      # Create entries for both clients
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "Work for Test Company"
      })
      
      time_entry_fixture(user, %{
        project_id: other_project.id,
        date: ~D[2026-03-15],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "Work for Other Company"
      })

      conn = get(conn, ~p"/exports/time-entries?client_id=#{client.id}")
      
      # Check filename includes "filtered" when client filter is used
      assert [content_disposition] = get_resp_header(conn, "content-disposition")
      assert String.contains?(content_disposition, "jikan_time_entries_filtered")
      
      # Check content
      csv_content = response(conn, 200)
      assert String.contains?(csv_content, "Work for Test Company")
      refute String.contains?(csv_content, "Work for Other Company")
    end

    test "exports with year filter", %{conn: conn, user: user, project: project} do
      # Create entries in different years
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2025-12-15],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "2025 work"
      })
      
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "2026 work"
      })

      conn = get(conn, ~p"/exports/time-entries?year=2026")
      
      # Check filename
      assert [content_disposition] = get_resp_header(conn, "content-disposition")
      assert String.contains?(content_disposition, "jikan_time_entries_2026")
      
      # Check content
      csv_content = response(conn, 200)
      assert String.contains?(csv_content, "2026 work")
      refute String.contains?(csv_content, "2025 work")
    end

    test "exports with month filter", %{conn: conn, user: user, project: project} do
      # Create entries in different months
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-02-15],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "February work"
      })
      
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "March work"
      })

      conn = get(conn, ~p"/exports/time-entries?year=2026&month=3")
      
      # Check filename
      assert [content_disposition] = get_resp_header(conn, "content-disposition")
      assert String.contains?(content_disposition, "jikan_time_entries_2026_Mar")
      
      # Check content
      csv_content = response(conn, 200)
      assert String.contains?(csv_content, "March work")
      refute String.contains?(csv_content, "February work")
    end

    test "exports with week filter", %{conn: conn, user: user, project: project} do
      # Create entries in different weeks (week 11 is March 9-15, 2026)
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-10],  # Week 11
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "Week 11 work"
      })
      
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-20],  # Week 12
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "Week 12 work"
      })

      conn = get(conn, ~p"/exports/time-entries?year=2026&week=11")
      
      # Check filename
      assert [content_disposition] = get_resp_header(conn, "content-disposition")
      assert String.contains?(content_disposition, "jikan_time_entries_2026_W11")
      
      # Check content
      csv_content = response(conn, 200)
      assert String.contains?(csv_content, "Week 11 work")
      refute String.contains?(csv_content, "Week 12 work")
    end

    test "exports with combined filters", %{conn: conn, user: user, client: client, project: project} do
      # Create another client
      other_client = client_fixture(user, %{name: "Other Company"})
      other_project = project_fixture(user, %{
        name: "Other Project",
        client_id: other_client.id,
        archived: false
      })
      
      # Create various entries
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-10],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "Correct entry"  # Right client, right month
      })
      
      time_entry_fixture(user, %{
        project_id: other_project.id,
        date: ~D[2026-03-10],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "Wrong client"  # Wrong client, right month
      })
      
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-02-10],
        duration_minutes: 60,
        pause_duration_minutes: 0,
        description: "Wrong month"  # Right client, wrong month
      })

      conn = get(conn, ~p"/exports/time-entries?client_id=#{client.id}&year=2026&month=3")
      
      # Check filename
      assert [content_disposition] = get_resp_header(conn, "content-disposition")
      assert String.contains?(content_disposition, "jikan_time_entries_filtered_2026_Mar")
      
      # Check content
      csv_content = response(conn, 200)
      assert String.contains?(csv_content, "Correct entry")
      refute String.contains?(csv_content, "Wrong client")
      refute String.contains?(csv_content, "Wrong month")
    end

    test "uses European CSV format with semicolon separator and comma decimals", %{conn: conn, user: user, project: project} do
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        start_time: ~T[09:00:00],
        end_time: ~T[10:30:00],
        duration_minutes: 90,  # 1.5 hours
        pause_duration_minutes: 15,  # 0.25 hours
        billable: true,
        hourly_rate: Decimal.new("450.50"),
        total_amount: Decimal.new("563.13"),  # Based on net duration (1.25 * 450.50 = 563.125)
        description: "Test; with semicolon"
      })

      conn = get(conn, ~p"/exports/time-entries")
      csv_content = response(conn, 200)
      
      # Check semicolon separator
      lines = String.split(csv_content, "\n")
      header = List.first(lines)
      fields = String.split(header, ";")
      assert length(fields) == 13  # Should have 13 fields
      
      # Check decimal separator is comma
      assert String.contains?(csv_content, "450,5")  # Hourly rate
      assert String.contains?(csv_content, "563,13")  # Total amount
      
      # Check that field with semicolon is properly escaped
      assert String.contains?(csv_content, "\"Test; with semicolon\"")
    end

    test "calculates net duration correctly in export", %{conn: conn, user: user, project: project} do
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        duration_minutes: 480,  # 8 hours
        pause_duration_minutes: 60,  # 1 hour pause
        description: "Full day with break"
      })

      conn = get(conn, ~p"/exports/time-entries")
      csv_content = response(conn, 200)
      
      lines = String.split(csv_content, "\n")
      data_line = Enum.at(lines, 1)
      fields = String.split(data_line, ";")
      
      # Net duration should be 7:00 (not 8:00)
      duration_field = Enum.at(fields, 6)
      assert duration_field == "7:00"
      
      # Pause should still be shown separately
      pause_field = Enum.at(fields, 7)
      assert pause_field == "1:00"
    end

    test "requires authentication", %{conn: conn} do
      # Log out
      conn = conn |> delete(~p"/users/log-out")
      
      # Try to access export without authentication
      conn = get(conn, ~p"/exports/time-entries")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end
end