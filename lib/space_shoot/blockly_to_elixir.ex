defmodule SpaceShoot.BlocklyToElixir do
  def convert(%{"blocks" => %{"blocks" => blocks}}) do
    blocks |> Enum.map(&block_to_code/1) |> Enum.join("\n")
  end

  defp block_to_code(%{"type" => "sprite_handler", "fields" => %{"EVENT" => event}} = block) do
    body = block |> get_in(["inputs", "BODY", "block"]) |> body_to_code()

    """
    def #{event}(sprite) do
    #{body}end
    """
  end

  defp block_to_code(_block), do: ""

  defp body_to_code(nil), do: ""

  defp body_to_code(%{"type" => "sprite_action", "fields" => %{"ACTION" => action, "AMOUNT" => amount}}) do
    "  sprite\n  |> #{action}(#{amount})\n"
  end
end
