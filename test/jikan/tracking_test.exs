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
end
