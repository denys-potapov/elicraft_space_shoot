defmodule SpaceShootWeb.UserSocket do
  use Phoenix.LiveView.Socket

  channel "game:*", SpaceShootWeb.GameChannel
end
