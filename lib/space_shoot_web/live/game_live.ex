defmodule SpaceShootWeb.GameLive do
  use SpaceShootWeb, :live_view

  alias SpaceShoot.Game

  @tick_ms 16

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@tick_ms, self(), :tick)
    end

    Process.put(:game_state, Game.initial_state())
    {:ok, socket}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    Process.put(:game_state, Game.key_down(Process.get(:game_state), key))
    {:noreply, socket}
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    Process.put(:game_state, Game.key_up(Process.get(:game_state), key))
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    new_state = Game.tick(Process.get(:game_state))
    Process.put(:game_state, new_state)
    sprites = Game.render_sprites(new_state)

    {:noreply, push_event(socket, "render_frame", %{sprites: sprites})}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        id="game-canvas"
        phx-hook=".GameCanvas"
        phx-update="ignore"
        class="border border-base-300 rounded-lg mx-auto block w-[800px] h-[600px] overflow-hidden"
      >
      </div>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".GameCanvas">
      import { Application, Assets, Sprite, Texture, Rectangle } from "pixi.js";

      const GAME_KEYS = new Set(["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", " "]);

      export default {
        async mounted() {
          const app = new Application();
          await app.init({ width: 800, height: 600, background: 0x1a1a2e });
          this.el.appendChild(app.canvas);
          this.pixiApp = app;

          // Load spritesheet base textures
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

          // Keyboard
          this._onKeyDown = (e) => {
            if (GAME_KEYS.has(e.key)) {
              e.preventDefault();
              this.pushEvent("keydown", {key: e.key});
            }
          };
          this._onKeyUp = (e) => {
            if (GAME_KEYS.has(e.key)) {
              e.preventDefault();
              this.pushEvent("keyup", {key: e.key});
            }
          };
          window.addEventListener("keydown", this._onKeyDown);
          window.addEventListener("keyup", this._onKeyUp);
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

          // Grow pool if needed
          while (pool.length < sprites.length) {
            const s = new Sprite();
            s.anchor.set(0.5);
            stage.addChild(s);
            pool.push(s);
          }

          // Update visible sprites
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

          // Hide excess pool sprites
          for (let i = sprites.length; i < pool.length; i++) {
            pool[i].visible = false;
          }
        },

        destroyed() {
          if (this.pixiApp) { this.pixiApp.destroy(true); }
          window.removeEventListener("keydown", this._onKeyDown);
          window.removeEventListener("keyup", this._onKeyUp);
        }
      }
    </script>
    """
  end
end
