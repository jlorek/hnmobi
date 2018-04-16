defmodule HnmobiWeb.CatchAllController do
  use HnmobiWeb, :controller

  def index(conn, _params) do
    conn |> Phoenix.Controller.render(HnmobiWeb.ErrorView, :"404")
  end
end