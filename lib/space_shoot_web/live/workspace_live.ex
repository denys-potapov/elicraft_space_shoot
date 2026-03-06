defmodule SpaceShootWeb.WorkspaceLive do
  use SpaceShootWeb, :live_view

  alias SpaceShoot.Workspace
  alias SpaceShootWeb.GameCanvasComponent

  @default_workspace_id "repeat_loop"

  def mount(_params, _session, socket) do
    workspace_json =
      Workspace.get_workspace(@default_workspace_id) |> Jason.encode!()

    socket =
      socket
      |> assign(
        workspace_options: Workspace.list_workspaces(),
        selected_workspace: @default_workspace_id,
        workspace_json: workspace_json
      )

    {:ok, socket}
  end

  def handle_event("select_workspace", %{"workspace" => id}, socket) do
    workspace_json = Workspace.get_workspace(id) |> Jason.encode!()

    socket =
      socket
      |> assign(selected_workspace: id)
      |> push_event("load_workspace", %{workspace: workspace_json})

    {:noreply, socket}
  end

  def handle_event("save", %{"workspace" => workspace_json}, socket) do
    case Jason.decode(workspace_json) do
      {:ok, workspace} ->
        IO.inspect(workspace, label: "Saved workspace")
        {:noreply, put_flash(socket, :info, "Workspace saved!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Invalid workspace JSON")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} fullwidth>
      <div class={["flex h-full"]}>
        <%!-- Left sidebar: modules list + toolbar --%>
        <aside class={["w-56 shrink-0 flex flex-col border-r border-base-300 bg-base-200/50"]}>
          <div class={["flex items-center gap-1 px-3 py-2 border-b border-base-300"]}>
            <span class={["text-sm font-semibold flex-1"]}>Modules</span>
            <button
              id="save-workspace"
              title="Save"
              class={["btn btn-ghost btn-sm btn-square"]}
            >
              <.icon name="hero-arrow-down-tray" class="size-4" />
            </button>
            <button
              title="Open"
              class={["btn btn-ghost btn-sm btn-square"]}
            >
              <.icon name="hero-folder-open" class="size-4" />
            </button>
          </div>
          <nav class={["flex-1 overflow-y-auto"]}>
            <ul class={["menu menu-sm"]}>
              <%= for {label, id} <- @workspace_options do %>
                <li>
                  <button
                    type="button"
                    phx-click="select_workspace"
                    phx-value-workspace={id}
                    class={[id == @selected_workspace && "font-bold bg-base-300"]}
                  >
                    <.icon name="hero-cube" class="size-4 opacity-60" />
                    {label}
                  </button>
                </li>
              <% end %>
            </ul>
          </nav>
        </aside>

        <%!-- Middle + Splitter + Right: managed by splitter hook --%>
        <div
          id="split-container"
          phx-hook=".SplitPanel"
          class={["flex flex-1 min-w-0 h-full"]}
        >
          <%!-- Middle: Blockly workspace --%>
          <div id="split-left" class={["flex-1 min-w-0 h-full"]}>
            <div
              id="blockly-workspace"
              phx-hook=".BlocklyWorkspace"
              phx-update="ignore"
              data-workspace={@workspace_json}
              class={["h-full"]}
            >
            </div>
          </div>

          <%!-- Splitter handle --%>
          <div
            id="split-handle"
            class={[
              "w-1.5 shrink-0 cursor-col-resize bg-base-300",
              "hover:bg-primary/40 active:bg-primary/60 transition-colors"
            ]}
          >
          </div>

          <%!-- Right: Game canvas --%>
          <div id="split-right" style="width:820px" class={["shrink-0 h-full"]}>
            <.live_component module={GameCanvasComponent} id="game" />
          </div>
        </div>
      </div>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".BlocklyWorkspace">
      import * as Blockly from "blockly";

      export default {
        mounted() {
          this.workspace = Blockly.inject(this.el, {
            toolbox: {
              kind: "categoryToolbox",
              contents: [
                {
                  kind: "category",
                  name: "Logic",
                  categorystyle: "logic_category",
                  contents: [
                    { kind: "block", type: "controls_if" },
                    { kind: "block", type: "logic_compare" },
                    { kind: "block", type: "logic_operation" },
                    { kind: "block", type: "logic_negate" },
                    { kind: "block", type: "logic_boolean" },
                  ],
                },
                {
                  kind: "category",
                  name: "Loops",
                  categorystyle: "loop_category",
                  contents: [
                    { kind: "block", type: "controls_repeat_ext" },
                    { kind: "block", type: "controls_whileUntil" },
                    { kind: "block", type: "controls_for" },
                    { kind: "block", type: "controls_forEach" },
                  ],
                },
                {
                  kind: "category",
                  name: "Math",
                  categorystyle: "math_category",
                  contents: [
                    { kind: "block", type: "math_number" },
                    { kind: "block", type: "math_arithmetic" },
                    { kind: "block", type: "math_single" },
                  ],
                },
                {
                  kind: "category",
                  name: "Text",
                  categorystyle: "text_category",
                  contents: [
                    { kind: "block", type: "text" },
                    { kind: "block", type: "text_join" },
                    { kind: "block", type: "text_length" },
                  ],
                },
                {
                  kind: "category",
                  name: "Variables",
                  custom: "VARIABLE",
                },
                {
                  kind: "category",
                  name: "Functions",
                  custom: "PROCEDURE",
                },
              ],
            },
          });

          // Load initial workspace state
          const data = this.el.dataset.workspace;
          if (data) {
            try {
              const state = JSON.parse(data);
              Blockly.serialization.workspaces.load(state, this.workspace);
            } catch (e) {
              console.error("Failed to load workspace:", e);
            }
          }

          // Listen for workspace changes from server
          this.handleEvent("load_workspace", ({ workspace }) => {
            try {
              const state = JSON.parse(workspace);
              this.workspace.clear();
              Blockly.serialization.workspaces.load(state, this.workspace);
            } catch (e) {
              console.error("Failed to load workspace:", e);
            }
          });

          // Handle save button
          const saveBtn = document.getElementById("save-workspace");
          this._onSave = () => {
            const state = Blockly.serialization.workspaces.save(this.workspace);
            this.pushEvent("save", { workspace: JSON.stringify(state) });
          };
          saveBtn.addEventListener("click", this._onSave);
        },

        destroyed() {
          const saveBtn = document.getElementById("save-workspace");
          if (saveBtn) saveBtn.removeEventListener("click", this._onSave);
          if (this.workspace) this.workspace.dispose();
        },
      };
    </script>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".SplitPanel">
      export default {
        mounted() {
          const handle = document.getElementById("split-handle");
          const right = document.getElementById("split-right");
          const container = this.el;
          let dragging = false;

          const onMouseDown = (e) => {
            e.preventDefault();
            dragging = true;
            document.body.style.cursor = "col-resize";
            document.body.style.userSelect = "none";
            // Prevent iframe from stealing mouse events
            right.style.pointerEvents = "none";
          };

          const onMouseMove = (e) => {
            if (!dragging) return;
            const containerRect = container.getBoundingClientRect();
            const newRightWidth = containerRect.right - e.clientX - handle.offsetWidth / 2;
            const clamped = Math.max(200, Math.min(newRightWidth, containerRect.width - 200));
            right.style.width = clamped + "px";
            // Tell Blockly to recalculate its size
            window.dispatchEvent(new Event("resize"));
          };

          const onMouseUp = () => {
            if (!dragging) return;
            dragging = false;
            document.body.style.cursor = "";
            document.body.style.userSelect = "";
            right.style.pointerEvents = "";
          };

          handle.addEventListener("mousedown", onMouseDown);
          document.addEventListener("mousemove", onMouseMove);
          document.addEventListener("mouseup", onMouseUp);

          this._cleanup = () => {
            handle.removeEventListener("mousedown", onMouseDown);
            document.removeEventListener("mousemove", onMouseMove);
            document.removeEventListener("mouseup", onMouseUp);
          };
        },

        destroyed() {
          if (this._cleanup) this._cleanup();
        }
      }
    </script>
    """
  end
end
