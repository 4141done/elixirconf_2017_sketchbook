defmodule SketchpadWeb.PageController do
  use SketchpadWeb, :controller

  plug :require_user when not action in [:signin]

  def index(conn, _params) do
    render conn, "index.html"
  end

  def signin(conn, %{"user" => %{"username" => username}}) do
    user_color = Enum.random(["#2ecc71", "#3498db", "#e74c3c", "#f1c40f"])
    IO.puts "user color is #{user_color}"
    conn
    |> put_session(:user_id, username)
    |> put_session(:user_color, user_color)
    |> redirect(to: "/")
  end

  defp require_user(conn, _) do
    if user = get_session(conn, :user_id) do
        conn
        |> assign(:user_id, user)
        |> assign(:user_token, Phoenix.Token.sign(conn, "user token", user))
        |> assign(:user_color, get_session(conn, :user_color))

    else
        conn
        |> put_flash(:error, "Please signin to sketch!")
        |> render("signin.html")
        |> halt() # for a plug method we need to do this otherwise the controller action is run after this
    end
  end
end
