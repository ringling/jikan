defmodule JikanWeb.Plugs.Authorize do
  @moduledoc "Plug that verifies the current user has the required role."
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  def init(opts), do: opts

  def call(conn, roles) when is_list(roles) do
    user = conn.assigns[:current_user]

    if user && user.role in Enum.map(roles, &to_string/1) do
      conn
    else
      conn
      |> put_flash(:error, "You don't have permission to access this page.")
      |> redirect(to: "/dashboard")
      |> halt()
    end
  end
end