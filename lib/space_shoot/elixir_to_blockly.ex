defmodule SpaceShoot.ElixirToBlockly do
  def convert(code) do
    {:ok, ast} = Code.string_to_quoted(code)
    blocks = ast_to_blocks(ast)

    %{
      "blocks" => %{
        "languageVersion" => 0,
        "blocks" => blocks
      }
    }
  end

  defp ast_to_blocks({:def, _, [{name, _, _args}, [do: body]]}) do
    block = %{
      "type" => "sprite_handler",
      "x" => 20,
      "y" => 20,
      "fields" => %{"EVENT" => to_string(name)}
    }

    case body_to_block(body) do
      nil -> [block]
      inner -> [Map.put(block, "inputs", %{"BODY" => %{"block" => inner}})]
    end
  end

  defp ast_to_blocks(_ast), do: []

  defp body_to_block({:__block__, _, []}), do: nil
  defp body_to_block(nil), do: nil

  defp body_to_block({:|>, _, [_sprite, {action, _, args}]}) do
    %{
      "type" => "sprite_action",
      "fields" => %{
        "ACTION" => to_string(action),
        "AMOUNT" => extract_amount(args)
      }
    }
  end

  defp extract_amount([amount]) when is_integer(amount), do: amount
  defp extract_amount(_), do: nil
end
