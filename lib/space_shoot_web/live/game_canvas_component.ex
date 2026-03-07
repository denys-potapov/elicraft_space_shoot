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

    if !socket.assigns.initialized && assigns[:connected] do
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
      phx-target={@myself}
      class={["w-full h-full"]}
    >
      <div
        id="game-canvas"
        phx-hook=".GameCanvas"
        phx-update="ignore"
        class={["w-full h-full overflow-hidden flex items-center justify-center"]}
      >
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".GameCanvas">
      import { Application, Assets, Sprite, Texture, Rectangle } from "pixi.js";

      const GAME_KEYS = new Set(["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", " "]);

      const GAME_W = 800;
      const GAME_H = 600;

      export default {
        async mounted() {
          this._onKeyDown = (e) => {
            if (GAME_KEYS.has(e.key) && !e.repeat) {
              this.pushEventTo(this.el, "keydown", {key: e.key});
            }
          };
          this._onKeyUp = (e) => {
            if (GAME_KEYS.has(e.key)) {
              this.pushEventTo(this.el, "keyup", {key: e.key});
            }
          };
          window.addEventListener("keydown", this._onKeyDown);
          window.addEventListener("keyup", this._onKeyUp);
          const app = new Application();
          await app.init({
            width: GAME_W,
            height: GAME_H,
            background: 0x87CEEB,
          });
          this.el.appendChild(app.canvas);
          this.pixiApp = app;

          // Scale canvas via CSS to fit container, maintaining aspect ratio
          this._resize = () => {
            const cw = this.el.clientWidth;
            const ch = this.el.clientHeight;
            const scale = Math.min(cw / GAME_W, ch / GAME_H);
            const w = Math.floor(GAME_W * scale);
            const h = Math.floor(GAME_H * scale);
            app.canvas.style.width = w + "px";
            app.canvas.style.height = h + "px";
          };
          this._resizeObserver = new ResizeObserver(() => this._resize());
          this._resizeObserver.observe(this.el);
          this._resize();

          this.baseTextures = {};
          this.textureCache = {};
          this.spritePool = [];
          this.assetsReady = false;

          this.handleEvent("render_frame", ({sprites}) => {
            if (this.assetsReady) this._updateSprites(sprites);
          });

          const [shipsTexture, tilesTexture] = await Promise.all([
            Assets.load("/images/shmup/ships.png"),
            Assets.load("/images/shmup/tiles.png"),
          ]);
          this.baseTextures = {
            "shmup/ships.png": shipsTexture,
            "shmup/tiles.png": tilesTexture,
          };
          this.assetsReady = true;
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
          window.removeEventListener("keydown", this._onKeyDown);
          window.removeEventListener("keyup", this._onKeyUp);
          if (this._resizeObserver) this._resizeObserver.disconnect();
          if (this.pixiApp) { this.pixiApp.destroy(true); }
        }
      }
    </script>
    </div>
    """
  end
end
