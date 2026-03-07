defmodule SpaceShootWeb.GameLive do
  use SpaceShootWeb, :live_view

  alias SpaceShootWeb.GameCanvasComponent

  def mount(_params, _session, socket) do
    {:ok, assign(socket, connected: connected?(socket))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} fullwidth>
      <div class={["h-full bg-gray-800"]}>
        <.live_component module={GameCanvasComponent} id="game" connected={@connected} />
      </div>
    </Layouts.app>
    """
  end
end
