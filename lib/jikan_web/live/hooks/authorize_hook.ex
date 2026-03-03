defmodule JikanWeb.Live.Hooks.AuthorizeHook do
  @moduledoc "LiveView on_mount hook for role-based access control."
  import Phoenix.LiveView

  def on_mount(:admin_required, params, session, socket) do
    # First ensure the user is authenticated
    case JikanWeb.UserAuth.on_mount(:ensure_authenticated, params, session, socket) do
      {:cont, socket} ->
        if Jikan.Accounts.User.admin?(socket.assigns.current_user) do
          {:cont, socket}
        else
          {:halt, socket |> put_flash(:error, "Admin access required.") |> redirect(to: "/dashboard")}
        end
      
      {:halt, socket} ->
        {:halt, socket}
    end
  end

  def on_mount(:manager_required, params, session, socket) do
    # First ensure the user is authenticated
    case JikanWeb.UserAuth.on_mount(:ensure_authenticated, params, session, socket) do
      {:cont, socket} ->
        if Jikan.Accounts.User.manager_or_above?(socket.assigns.current_user) do
          {:cont, socket}
        else
          {:halt, socket |> put_flash(:error, "Manager access required.") |> redirect(to: "/dashboard")}
        end
      
      {:halt, socket} ->
        {:halt, socket}
    end
  end
end