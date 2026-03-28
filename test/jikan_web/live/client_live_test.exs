defmodule JikanWeb.ClientLiveTest do
  use JikanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jikan.TrackingFixtures

  @update_attrs %{active: false, name: "some updated name", contact_email: "some updated contact_email"}
  @invalid_attrs %{active: false, name: nil, contact_email: nil}
  defp create_client(%{conn: conn}) do
    user = Jikan.AccountsFixtures.user_fixture()
    # Update user role to manager
    {:ok, user} = Jikan.Repo.update(Ecto.Changeset.change(user, role: "manager"))
    client = client_fixture(user)
    conn = log_in_user(conn, user)

    %{client: client, user: user, conn: conn}
  end

  describe "Index" do
    setup [:create_client]

    test "lists all clients", %{conn: conn, client: client} do
      {:ok, _index_live, html} = live(conn, ~p"/clients")

      assert html =~ "Listing Clients"
      assert html =~ client.name
    end

    test "saves new client", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/clients")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Client")
               |> render_click()
               |> follow_redirect(conn, ~p"/clients/new")

      assert render(form_live) =~ "New Client"

      assert form_live
             |> form("#client-form", client: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      # Create unique client attributes to avoid name conflicts
      unique_attrs = %{
        active: true,
        name: "unique client #{System.unique_integer([:positive])}",
        contact_email: "unique#{System.unique_integer([:positive])}@example.com"
      }

      assert {:ok, index_live, _html} =
               form_live
               |> form("#client-form", client: unique_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/clients")

      html = render(index_live)
      assert html =~ "Client created successfully"
      assert html =~ "unique client"
    end

    test "updates client in listing", %{conn: conn, client: client} do
      {:ok, index_live, _html} = live(conn, ~p"/clients")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#clients-#{client.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/clients/#{client}/edit")

      assert render(form_live) =~ "Edit Client"

      assert form_live
             |> form("#client-form", client: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#client-form", client: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/clients")

      html = render(index_live)
      assert html =~ "Client updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes client in listing", %{conn: conn, client: client} do
      {:ok, index_live, _html} = live(conn, ~p"/clients")

      assert index_live |> element("#clients-#{client.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#clients-#{client.id}")
    end
  end

  describe "Show" do
    setup [:create_client]

    test "displays client", %{conn: conn, client: client} do
      {:ok, _show_live, html} = live(conn, ~p"/clients/#{client}")

      assert html =~ "Show Client"
      assert html =~ client.name
    end

    test "updates client and returns to show", %{conn: conn, client: client} do
      {:ok, show_live, _html} = live(conn, ~p"/clients/#{client}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/clients/#{client}/edit?return_to=show")

      assert render(form_live) =~ "Edit Client"

      assert form_live
             |> form("#client-form", client: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#client-form", client: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/clients/#{client}")

      html = render(show_live)
      assert html =~ "Client updated successfully"
      assert html =~ "some updated name"
    end
  end
end
