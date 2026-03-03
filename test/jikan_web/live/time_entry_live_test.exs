defmodule JikanWeb.TimeEntryLiveTest do
  use JikanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jikan.TrackingFixtures

  @create_attrs %{date: "2026-03-02", description: "some description", start_time: "14:00", end_time: "14:00", duration_minutes: 42, billable: true}
  @update_attrs %{date: "2026-03-03", description: "some updated description", start_time: "15:01", end_time: "15:01", duration_minutes: 43, billable: false}
  @invalid_attrs %{date: nil, description: nil, start_time: nil, end_time: nil, duration_minutes: nil, billable: false}
  defp create_time_entry(_) do
    time_entry = time_entry_fixture()

    %{time_entry: time_entry}
  end

  describe "Index" do
    setup [:create_time_entry]

    test "lists all time_entries", %{conn: conn, time_entry: time_entry} do
      {:ok, _index_live, html} = live(conn, ~p"/time_entries")

      assert html =~ "Listing Time entries"
      assert html =~ time_entry.description
    end

    test "saves new time_entry", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/time_entries")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Time entry")
               |> render_click()
               |> follow_redirect(conn, ~p"/time_entries/new")

      assert render(form_live) =~ "New Time entry"

      assert form_live
             |> form("#time_entry-form", time_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#time_entry-form", time_entry: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/time_entries")

      html = render(index_live)
      assert html =~ "Time entry created successfully"
      assert html =~ "some description"
    end

    test "updates time_entry in listing", %{conn: conn, time_entry: time_entry} do
      {:ok, index_live, _html} = live(conn, ~p"/time_entries")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#time_entries-#{time_entry.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/time_entries/#{time_entry}/edit")

      assert render(form_live) =~ "Edit Time entry"

      assert form_live
             |> form("#time_entry-form", time_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#time_entry-form", time_entry: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/time_entries")

      html = render(index_live)
      assert html =~ "Time entry updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes time_entry in listing", %{conn: conn, time_entry: time_entry} do
      {:ok, index_live, _html} = live(conn, ~p"/time_entries")

      assert index_live |> element("#time_entries-#{time_entry.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#time_entries-#{time_entry.id}")
    end
  end

  describe "Show" do
    setup [:create_time_entry]

    test "displays time_entry", %{conn: conn, time_entry: time_entry} do
      {:ok, _show_live, html} = live(conn, ~p"/time_entries/#{time_entry}")

      assert html =~ "Show Time entry"
      assert html =~ time_entry.description
    end

    test "updates time_entry and returns to show", %{conn: conn, time_entry: time_entry} do
      {:ok, show_live, _html} = live(conn, ~p"/time_entries/#{time_entry}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/time_entries/#{time_entry}/edit?return_to=show")

      assert render(form_live) =~ "Edit Time entry"

      assert form_live
             |> form("#time_entry-form", time_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#time_entry-form", time_entry: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/time_entries/#{time_entry}")

      html = render(show_live)
      assert html =~ "Time entry updated successfully"
      assert html =~ "some updated description"
    end
  end
end
