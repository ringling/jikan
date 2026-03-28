defmodule JikanWeb.PageControllerTest do
  use JikanWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Time tracking made simple"
  end
end
