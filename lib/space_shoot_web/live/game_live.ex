defmodule SpaceShootWeb.GameLive do
  use SpaceShootWeb, :live_view

  alias SpaceShoot.Game

  @tick_ms 33

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@tick_ms, self(), :tick)
    end

    {:ok, assign(socket, game_state: Game.initial_state())}
  end

  def handle_info(:tick, socket) do
    new_state = Game.tick(socket.assigns.game_state)
    sprites = Game.render_sprites(new_state)

    {:noreply,
     socket
     |> assign(:game_state, new_state)
     |> push_event("render_frame", %{sprites: sprites})}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <canvas
        id="game-canvas"
        phx-hook=".GameCanvas"
        phx-update="ignore"
        width="800"
        height="600"
        class="border border-base-300 rounded-lg bg-base-200 mx-auto block"
      >
      </canvas>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".GameCanvas">
      const imageCache = {};

      function loadImage(src) {
        if (!imageCache[src]) {
          const img = new Image();
          img.src = `/images/${src}`;
          imageCache[src] = img;
        }
        return imageCache[src];
      }

      export default {
        mounted() {
          this.canvas = this.el;
          this.ctx = this.canvas.getContext("2d");

          this.handleEvent("render_frame", ({sprites}) => {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
            for (const s of sprites) {
              const img = loadImage(s.image);
              if (img.complete) {
                this.ctx.drawImage(img, s.x, s.y, s.width, s.height);
              }
            }
          });
        }
      }
    </script>
    """
  end
end
