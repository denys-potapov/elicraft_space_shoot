defmodule SpaceShootWeb.Router do
  use SpaceShootWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SpaceShootWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpaceShootWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/game", GameLive
    live "/workspace", WorkspaceLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", SpaceShootWeb do
  #   pipe_through :api
  # end
end
