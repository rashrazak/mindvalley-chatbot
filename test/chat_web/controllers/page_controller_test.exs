defmodule ChatWeb.PageControllerTest do
  use ChatWeb.ConnCase

  test "LIVE /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Mindvalley Chatbot"
  end
end
