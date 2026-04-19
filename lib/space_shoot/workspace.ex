defmodule SpaceShoot.Workspace do
  @workspaces %{
    "empty_handler" => """
    def handle_tick(sprite) do
    end
    """,
    "move_left" => """
    def handle_tick(sprite) do
      sprite
      |> move_left(4)
    end
    """
  }

  @workspace_labels %{
    "empty_handler" => "Empty Handler",
    "move_left" => "Move Left"
  }

  def list_workspaces do
    Enum.map(@workspace_labels, fn {id, label} -> {label, id} end)
  end

  def get_workspace(id) do
    @workspaces |> Map.fetch!(id) |> SpaceShoot.ElixirToBlockly.convert()
  end
end
