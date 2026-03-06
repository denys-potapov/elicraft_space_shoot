defmodule SpaceShootWeb.GameCanvasComponent do
  use SpaceShootWeb, :live_component

  alias SpaceShoot.Game

  @tick_ms 16

  def mount(socket) do
    {:ok, assign(socket, initialized: false)}
  end

  def update(%{tick: true}, socket) do
    new_state = Game.tick(Process.get(:game_state))
    Process.put(:game_state, new_state)
    sprites = Game.render_sprites(new_state)

    schedule_tick()
    {:ok, push_event(socket, "render_frame", %{sprites: sprites})}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if !socket.assigns.initialized do
      Process.put(:game_state, Game.initial_state())
      schedule_tick()
      {:ok, assign(socket, initialized: true)}
    else
      {:ok, socket}
    end
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    Process.put(:game_state, Game.key_down(Process.get(:game_state), key))
    {:noreply, socket}
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    Process.put(:game_state, Game.key_up(Process.get(:game_state), key))
    {:noreply, socket}
  end

  defp schedule_tick do
    send_update_after(__MODULE__, %{id: "game", tick: true}, @tick_ms)
  end

  def render(assigns) do
    ~H"""
    <div
      id="game-canvas-root"
      phx-window-keydown="keydown"
      phx-window-keyup="keyup"
      phx-target={@myself}
      phx-throttle="0"
      class={["w-full h-full"]}
    >
      <div
        id="game-canvas"
        phx-hook=".GameCanvas"
        phx-update="ignore"
        class={["w-full h-full overflow-hidden"]}
      >
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".GameCanvas">
      import { Application, Assets, Sprite, Texture, Rectangle } from "pixi.js";

      const GAME_KEYS = new Set(["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", " "]);

      export default {
        async mounted() {
          const app = new Application();
          await app.init({
            width: this.el.clientWidth,
            height: this.el.clientHeight,
            background: 0x1a1a2e,
            resizeTo: this.el,
          });
          this.el.appendChild(app.canvas);
          this.pixiApp = app;

          const [shipsTexture, tilesTexture] = await Promise.all([
            Assets.load("/images/shmup/ships.png"),
            Assets.load("/images/shmup/tiles.png"),
          ]);
          this.baseTextures = {
            "shmup/ships.png": shipsTexture,
            "shmup/tiles.png": tilesTexture,
          };
          this.textureCache = {};
          this.spritePool = [];

          this.handleEvent("render_frame", ({sprites}) => {
            this._updateSprites(sprites);
          });
        },

        _getTexture(image, sx, sy, sw, sh) {
          const key = `${image}:${sx},${sy},${sw},${sh}`;
          if (!this.textureCache[key]) {
            const base = this.baseTextures[image];
            if (!base) return null;
            this.textureCache[key] = new Texture({
              source: base.source,
              frame: new Rectangle(sx, sy, sw, sh),
            });
          }
          return this.textureCache[key];
        },

        _updateSprites(sprites) {
          const pool = this.spritePool;
          const stage = this.pixiApp.stage;

          while (pool.length < sprites.length) {
            const s = new Sprite();
            s.anchor.set(0.5);
            stage.addChild(s);
            pool.push(s);
          }

          for (let i = 0; i < sprites.length; i++) {
            const data = sprites[i];
            const pixiSprite = pool[i];
            const tex = this._getTexture(data.image, data.sx, data.sy, data.sw, data.sh);
            if (tex) pixiSprite.texture = tex;
            pixiSprite.x = data.x + data.width / 2;
            pixiSprite.y = data.y + data.height / 2;
            pixiSprite.width = data.width;
            pixiSprite.height = data.height;
            pixiSprite.rotation = data.rotation || 0;
            pixiSprite.visible = true;
          }

          for (let i = sprites.length; i < pool.length; i++) {
            pool[i].visible = false;
          }
        },

        destroyed() {
          if (this.pixiApp) { this.pixiApp.destroy(true); }
        }
      }
    </script>
    </div>
    """
  end
end
