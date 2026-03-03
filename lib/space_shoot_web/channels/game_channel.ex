defmodule SpaceShootWeb.GameChannel do
  use Phoenix.Channel

  def join("game:" <> _id, _params, socket) do
    {:ok, socket}
  end
end
