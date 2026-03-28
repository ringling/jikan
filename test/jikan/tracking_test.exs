defmodule Jikan.TrackingTest do
  use Jikan.DataCase

  alias Jikan.Tracking

  describe "clients" do
    alias Jikan.Tracking.Client

    import Jikan.TrackingFixtures

    @invalid_attrs %{active: nil, name: nil, contact_email: nil}

    test "list_clients/0 returns all clients" do
      client = client_fixture()
      assert Tracking.list_clients() == [client]
    end

    test "get_client!/1 returns the client with given id" do
      client = client_fixture()
      assert Tracking.get_client!(client.id) == client
    end

    test "create_client/1 with valid data creates a client" do
      valid_attrs = %{active: true, name: "some name", contact_email: "some contact_email"}

      assert {:ok, %Client{} = client} = Tracking.create_client(valid_attrs)
      assert client.active == true
      assert client.name == "some name"
      assert client.contact_email == "some contact_email"
    end

    test "create_client/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracking.create_client(@invalid_attrs)
    end

    test "update_client/2 with valid data updates the client" do
      client = client_fixture()
      update_attrs = %{active: false, name: "some updated name", contact_email: "some updated contact_email"}

      assert {:ok, %Client{} = client} = Tracking.update_client(client, update_attrs)
      assert client.active == false
      assert client.name == "some updated name"
      assert client.contact_email == "some updated contact_email"
    end

    test "update_client/2 with invalid data returns error changeset" do
      client = client_fixture()
      assert {:error, %Ecto.Changeset{}} = Tracking.update_client(client, @invalid_attrs)
      assert client == Tracking.get_client!(client.id)
    end

    test "delete_client/1 deletes the client" do
      client = client_fixture()
      assert {:ok, %Client{}} = Tracking.delete_client(client)
      assert_raise Ecto.NoResultsError, fn -> Tracking.get_client!(client.id) end
    end

    test "change_client/1 returns a client changeset" do
      client = client_fixture()
      assert %Ecto.Changeset{} = Tracking.change_client(client)
    end
  end

  describe "projects" do
    alias Jikan.Tracking.Project

    import Jikan.TrackingFixtures

    @invalid_attrs %{name: nil, description: nil, color: nil, archived: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Tracking.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Tracking.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{name: "some name", description: "some description", color: "some color", archived: true}

      assert {:ok, %Project{} = project} = Tracking.create_project(valid_attrs)
      assert project.name == "some name"
      assert project.description == "some description"
      assert project.color == "some color"
      assert project.archived == true
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracking.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", color: "some updated color", archived: false}

      assert {:ok, %Project{} = project} = Tracking.update_project(project, update_attrs)
      assert project.name == "some updated name"
      assert project.description == "some updated description"
      assert project.color == "some updated color"
      assert project.archived == false
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Tracking.update_project(project, @invalid_attrs)
      assert project == Tracking.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Tracking.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Tracking.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Tracking.change_project(project)
    end
  end

  describe "time_entries" do
    alias Jikan.Tracking.TimeEntry

    import Jikan.TrackingFixtures

    @invalid_attrs %{date: nil, description: nil, start_time: nil, end_time: nil, duration_minutes: nil, billable: nil}

    test "list_time_entries/0 returns all time_entries" do
      time_entry = time_entry_fixture()
      assert Tracking.list_time_entries() == [time_entry]
    end

    test "get_time_entry!/1 returns the time_entry with given id" do
      time_entry = time_entry_fixture()
      assert Tracking.get_time_entry!(time_entry.id) == time_entry
    end

    test "create_time_entry/1 with valid data creates a time_entry" do
      valid_attrs = %{date: ~D[2026-03-02], description: "some description", start_time: ~T[14:00:00], end_time: ~T[14:00:00], duration_minutes: 42, billable: true}

      assert {:ok, %TimeEntry{} = time_entry} = Tracking.create_time_entry(valid_attrs)
      assert time_entry.date == ~D[2026-03-02]
      assert time_entry.description == "some description"
      assert time_entry.start_time == ~T[14:00:00]
      assert time_entry.end_time == ~T[14:00:00]
      assert time_entry.duration_minutes == 42
      assert time_entry.billable == true
    end

    test "create_time_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracking.create_time_entry(@invalid_attrs)
    end

    test "update_time_entry/2 with valid data updates the time_entry" do
      time_entry = time_entry_fixture()
      update_attrs = %{date: ~D[2026-03-03], description: "some updated description", start_time: ~T[15:01:01], end_time: ~T[15:01:01], duration_minutes: 43, billable: false}

      assert {:ok, %TimeEntry{} = time_entry} = Tracking.update_time_entry(time_entry, update_attrs)
      assert time_entry.date == ~D[2026-03-03]
      assert time_entry.description == "some updated description"
      assert time_entry.start_time == ~T[15:01:01]
      assert time_entry.end_time == ~T[15:01:01]
      assert time_entry.duration_minutes == 43
      assert time_entry.billable == false
    end

    test "update_time_entry/2 with invalid data returns error changeset" do
      time_entry = time_entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Tracking.update_time_entry(time_entry, @invalid_attrs)
      assert time_entry == Tracking.get_time_entry!(time_entry.id)
    end

    test "delete_time_entry/1 deletes the time_entry" do
      time_entry = time_entry_fixture()
      assert {:ok, %TimeEntry{}} = Tracking.delete_time_entry(time_entry)
      assert_raise Ecto.NoResultsError, fn -> Tracking.get_time_entry!(time_entry.id) end
    end

    test "change_time_entry/1 returns a time_entry changeset" do
      time_entry = time_entry_fixture()
      assert %Ecto.Changeset{} = Tracking.change_time_entry(time_entry)
    end
  end

  describe "CSV export" do
    import Jikan.AccountsFixtures
    import Jikan.TrackingFixtures

    setup do
      user = user_fixture()
      client = client_fixture(user, %{name: "Test Company"})
      project = project_fixture(user, %{
        name: "Test Project",
        client_id: client.id,
        archived: false
      })
      
      %{user: user, client: client, project: project}
    end

    test "export_time_entries_to_csv/2 generates CSV with semicolon separator", %{user: user, project: project} do
      # Create a time entry
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        duration_minutes: 480,
        pause_duration_minutes: 60,
        billable: true,
        hourly_rate: Decimal.new("450.00"),
        total_amount: Decimal.new("1575.00"),
        description: "Test work"
      })

      csv = Tracking.export_time_entries_to_csv(user)
      
      # Check header uses semicolons
      assert String.starts_with?(csv, "Date;Company;Project;Description;Start Time;End Time;Duration;Pause Duration;Billable;Hourly Rate (DKK);Total Amount (DKK);Week;Month")
      
      # Check data row uses semicolons
      lines = String.split(csv, "\n")
      assert length(lines) >= 2
      
      data_line = Enum.at(lines, 1)
      fields = String.split(data_line, ";")
      
      # Should have 13 fields
      assert length(fields) == 13
    end

    test "export_time_entries_to_csv/2 formats decimals with comma separator", %{user: user, project: project} do
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        duration_minutes: 480,
        pause_duration_minutes: 60,
        billable: true,
        hourly_rate: Decimal.new("450.50"),
        # Total amount should be based on net duration: (480-60)/60 * 450.50 = 7 * 450.50 = 3153.50
        total_amount: Decimal.new("3153.50"),
        description: "Test work"
      })

      csv = Tracking.export_time_entries_to_csv(user)
      lines = String.split(csv, "\n")
      data_line = Enum.at(lines, 1)
      
      # Check that decimal numbers use comma
      assert String.contains?(data_line, "450,5")  # Hourly rate
      assert String.contains?(data_line, "3153,5") # Total amount
    end

    test "export_time_entries_to_csv/2 calculates net duration correctly", %{user: user, project: project} do
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        duration_minutes: 480,  # 8 hours
        pause_duration_minutes: 60,  # 1 hour pause
        description: "Test work"
      })

      csv = Tracking.export_time_entries_to_csv(user)
      lines = String.split(csv, "\n")
      data_line = Enum.at(lines, 1)
      fields = String.split(data_line, ";")
      
      # Net duration should be 7:00 (480 - 60 = 420 minutes = 7 hours)
      duration_field = Enum.at(fields, 6)
      assert duration_field == "7:00"
      
      # Pause duration should be 1:00
      pause_field = Enum.at(fields, 7)
      assert pause_field == "1:00"
    end

    test "export_time_entries_to_csv/2 handles nil values correctly", %{user: user, project: project} do
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        start_time: nil,
        end_time: nil,
        duration_minutes: 120,
        pause_duration_minutes: 0,  # Cannot be nil in database
        billable: false,
        hourly_rate: nil,
        total_amount: nil,
        description: "Manual entry"
      })

      csv = Tracking.export_time_entries_to_csv(user)
      lines = String.split(csv, "\n")
      data_line = Enum.at(lines, 1)
      fields = String.split(data_line, ";")
      
      # Check empty fields for nil values
      assert Enum.at(fields, 4) == ""  # Start time
      assert Enum.at(fields, 5) == ""  # End time
      assert Enum.at(fields, 7) == "0:00"  # Pause duration (nil becomes 0)
      assert Enum.at(fields, 9) == ""  # Hourly rate
      assert Enum.at(fields, 10) == "0,00"  # Total amount (non-billable)
    end

    test "export_time_entries_to_csv/2 escapes fields with special characters", %{user: user, project: project} do
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        description: "Work with; semicolon and \"quotes\"",
        duration_minutes: 60
      })

      csv = Tracking.export_time_entries_to_csv(user)
      lines = String.split(csv, "\n")
      data_line = Enum.at(lines, 1)
      
      # Should properly escape the description field
      assert String.contains?(data_line, "\"Work with; semicolon and \"\"quotes\"\"\"")
    end

    test "export_time_entries_to_csv/2 applies filters correctly", %{user: user, project: project, client: client} do
      # Create entries in different months
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-02-15],
        duration_minutes: 60,
        description: "February work"
      })
      
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        duration_minutes: 120,
        description: "March work"
      })

      # Test month filter
      csv = Tracking.export_time_entries_to_csv(user, %{"year" => "2026", "month" => "3"})
      
      assert String.contains?(csv, "March work")
      refute String.contains?(csv, "February work")
      
      # Test client filter
      csv_with_client = Tracking.export_time_entries_to_csv(user, %{"client_id" => to_string(client.id)})
      assert String.contains?(csv_with_client, "Test Company")
    end

    test "export_time_entries_to_csv/2 formats dates and times in local timezone", %{user: user, project: project} do
      # Create entry with specific UTC times
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        start_time: ~T[08:00:00],  # 08:00 UTC
        end_time: ~T[16:00:00],    # 16:00 UTC
        duration_minutes: 480,
        description: "Timezone test"
      })

      csv = Tracking.export_time_entries_to_csv(user)
      lines = String.split(csv, "\n")
      data_line = Enum.at(lines, 1)
      fields = String.split(data_line, ";")
      
      # Check date format (dd.mm.yy)
      assert Enum.at(fields, 0) == "15.03.26"
      
      # Times should be converted to CET (UTC+1 in March)
      assert Enum.at(fields, 4) == "09:00"  # Start time
      assert Enum.at(fields, 5) == "17:00"  # End time
    end

    test "export_time_entries_to_csv/2 formats week and month correctly", %{user: user, project: project} do
      time_entry_fixture(user, %{
        project_id: project.id,
        date: ~D[2026-03-15],
        duration_minutes: 60
      })

      csv = Tracking.export_time_entries_to_csv(user)
      lines = String.split(csv, "\n")
      data_line = Enum.at(lines, 1)
      fields = String.split(data_line, ";")
      
      # Check week format (W11 for March 15, 2026)
      assert Enum.at(fields, 11) == "W11"
      
      # Check month format (Mar for March)
      assert Enum.at(fields, 12) == "Mar"
    end
  end
end
