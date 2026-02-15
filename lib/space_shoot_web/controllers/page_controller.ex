defmodule SpaceShootWeb.PageController do
  use SpaceShootWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
