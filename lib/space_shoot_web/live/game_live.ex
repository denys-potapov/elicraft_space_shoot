defmodule SpaceShootWeb.GameLive do
  use SpaceShootWeb, :live_view

  alias SpaceShootWeb.GameCanvasComponent

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} fullwidth>
      <.live_component module={GameCanvasComponent} id="game" />
    </Layouts.app>
    """
  end
end
