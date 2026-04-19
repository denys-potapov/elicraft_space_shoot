defmodule SpaceShoot.ElixirToBlocklyTest do
  use ExUnit.Case, async: true

  alias SpaceShoot.ElixirToBlockly

  describe "convert/1" do
    test "empty handle_tick returns a sprite_handler block with no body" do
      code = """
      def handle_tick(sprite) do
      end
      """

      assert %{
               "blocks" => %{
                 "languageVersion" => 0,
                 "blocks" => [
                   %{
                     "type" => "sprite_handler",
                     "fields" => %{"EVENT" => "handle_tick"}
                   }
                 ]
               }
             } = ElixirToBlockly.convert(code)
    end

    test "handle_tick with pipe returns a sprite_handler with sprite_action body" do
      code = """
      def handle_tick(sprite) do
        sprite
        |> move_left(4)
      end
      """

      assert %{
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
             } = ElixirToBlockly.convert(code)
    end
  end
end
