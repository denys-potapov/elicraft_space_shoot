defmodule SpaceShootWeb.WorkspaceLive do
  use SpaceShootWeb, :live_view

  alias SpaceShoot.Workspace

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
    <Layouts.app flash={@flash}>
      <div class={["flex flex-col gap-4"]}>
        <div class={["flex items-center gap-4"]}>
          <form phx-change="select_workspace">
            <select
              name="workspace"
              class={["select select-bordered"]}
            >
              <%= for {label, id} <- @workspace_options do %>
                <option value={id} selected={id == @selected_workspace}>{label}</option>
              <% end %>
            </select>
          </form>

          <button
            id="save-workspace"
            class={["btn btn-primary"]}
          >
            Save
          </button>
        </div>

        <div class={["flex gap-4"]}>
          <div
            id="blockly-workspace"
            phx-hook=".BlocklyWorkspace"
            phx-update="ignore"
            data-workspace={@workspace_json}
            class={["flex-1 min-h-[480px] border border-base-300 rounded-lg"]}
          >
          </div>

          <iframe
            src={~p"/game"}
            class={["w-[820px] min-h-[480px] border border-base-300 rounded-lg"]}
          >
          </iframe>
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
    """
  end
end
