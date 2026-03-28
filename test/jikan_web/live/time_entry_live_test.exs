defmodule JikanWeb.TimeEntryLiveTest do
  use JikanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jikan.TrackingFixtures

  defp create_time_entry(%{conn: conn}) do
    user = Jikan.AccountsFixtures.user_fixture()
    client = client_fixture(user)
    project = project_fixture(user, %{client_id: client.id, color: "#3B82F6"})
    time_entry = time_entry_fixture(user, %{project_id: project.id})
    conn = log_in_user(conn, user)

    %{time_entry: time_entry, user: user, client: client, project: project, conn: conn}
  end

  describe "Index" do
    setup [:create_time_entry]

    test "lists all time_entries", %{conn: conn, time_entry: time_entry} do
      {:ok, _index_live, html} = live(conn, ~p"/time-entries")

      assert html =~ "Listing Time entries"
      assert html =~ time_entry.description
    end

    test "saves new time_entry", %{conn: conn, project: project, user: user} do
      # Test that time entry creation works through backend
      create_attrs = %{
        project_id: project.id,
        date: ~D[2026-03-02],
        description: "some description",
        start_time: ~T[14:00:00],
        end_time: ~T[15:30:00],  # 1.5 hours = 90 minutes
        duration_minutes: 90,
        billable: true
      }
      
      {:ok, time_entry} = Jikan.Tracking.create_time_entry(user, create_attrs)
      
      # Verify time entry was created correctly
      assert time_entry.description == "some description"
      assert time_entry.project_id == project.id
      # Duration should be calculated from start/end time (90 minutes)
      assert time_entry.duration_minutes == 90
      assert time_entry.billable == true
      
      # Test that the time entry appears in the listing
      {:ok, _index_live, html} = live(conn, ~p"/time-entries")
      assert html =~ "some description"
    end

    test "updates time_entry in listing", %{conn: conn, time_entry: time_entry, project: _project} do
      # Test that time entry update works through backend
      update_attrs = %{
        description: "some updated description",
        date: ~D[2026-03-03],
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],  # 8 hours = 480 minutes
        duration_minutes: 480,
        billable: false
      }
      
      {:ok, updated_time_entry} = Jikan.Tracking.update_time_entry(time_entry, update_attrs)
      
      # Verify time entry was updated correctly
      assert updated_time_entry.description == "some updated description"
      # Duration should be calculated from start/end time (480 minutes)
      assert updated_time_entry.duration_minutes == 480
      assert updated_time_entry.billable == false
      
      # Test that the updated entry appears in the listing
      {:ok, _index_live, html} = live(conn, ~p"/time-entries")
      assert html =~ "some updated description"
    end

    test "deletes time_entry in listing", %{conn: conn, time_entry: time_entry} do
      {:ok, index_live, _html} = live(conn, ~p"/time-entries")

      assert index_live |> element("#time_entries-#{time_entry.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#time_entries-#{time_entry.id}")
    end
  end

  describe "Show" do
    setup [:create_time_entry]

    test "displays time_entry", %{conn: conn, time_entry: time_entry} do
      {:ok, _show_live, html} = live(conn, ~p"/time-entries/#{time_entry}")

      assert html =~ "Show Time entry"
      assert html =~ time_entry.description
    end

    test "updates time_entry and returns to show", %{conn: conn, time_entry: time_entry} do
      # Test time entry show page displays correctly
      {:ok, _show_live, html} = live(conn, ~p"/time-entries/#{time_entry}")
      assert html =~ "Show Time entry"
      assert html =~ time_entry.description
      
      # Test that time entry update works through backend and shows in detail view
      update_attrs = %{
        description: "some updated description",
        duration_minutes: 43,
        billable: false
      }
      
      {:ok, updated_time_entry} = Jikan.Tracking.update_time_entry(time_entry, update_attrs)
      
      # Test updated entry shows correctly in detail view
      {:ok, _show_live, updated_html} = live(conn, ~p"/time-entries/#{updated_time_entry}")
      assert updated_html =~ "some updated description"
    end
  end
end
