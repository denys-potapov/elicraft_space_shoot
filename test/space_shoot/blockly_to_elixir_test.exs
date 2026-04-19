defmodule SpaceShoot.BlocklyToElixirTest do
  use ExUnit.Case, async: true

  alias SpaceShoot.BlocklyToElixir

  describe "convert/1" do
    test "sprite_handler with no body produces empty handle_tick" do
      workspace = %{
        "blocks" => %{
          "languageVersion" => 0,
          "blocks" => [
            %{
              "type" => "sprite_handler",
              "fields" => %{"EVENT" => "handle_tick"}
            }
          ]
        }
      }

      assert BlocklyToElixir.convert(workspace) == """
             def handle_tick(sprite) do
             end
             """
    end

    test "sprite_handler with sprite_action body produces pipe" do
      workspace = %{
        "blocks" => %{
          "languageVersion" => 0,
          "blocks" => [
            %{
              "type" => "sprite_handler",
              "fields" => %{"EVENT" => "handle_tick"},
              "inputs" => %{
                "BODY" => %{
                  "block" => %{
                    "type" => "sprite_action",
                    "fields" => %{"ACTION" => "move_left", "AMOUNT" => 4}
                  }
                }
              }
            }
          ]
        }
      }

      assert BlocklyToElixir.convert(workspace) == """
             def handle_tick(sprite) do
               sprite
               |> move_left(4)
             end
             """
    end
  end
end
