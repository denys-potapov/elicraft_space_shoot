defmodule SpaceShoot.Game do
  @moduledoc """
  Game state and tick logic.
  """

  @canvas_width 800
  @canvas_height 600

  def initial_state do
    %{
      sprites: [
        %{x: 100.0, y: 100.0, vx: 3.0, vy: 2.0, image: "logo.svg", width: 64, height: 64}
      ]
    }
  end

  def tick(state) do
    %{state | sprites: Enum.map(state.sprites, &move_sprite/1)}
  end

  def render_sprites(state) do
    Enum.map(state.sprites, fn s ->
      %{x: round(s.x), y: round(s.y), image: s.image, width: s.width, height: s.height}
    end)
  end

  defp move_sprite(s) do
    new_x = s.x + s.vx
    new_y = s.y + s.vy

    {new_x, vx} = bounce(new_x, s.vx, @canvas_width - s.width)
    {new_y, vy} = bounce(new_y, s.vy, @canvas_height - s.height)

    %{s | x: new_x, y: new_y, vx: vx, vy: vy}
  end

  defp bounce(pos, vel, _max) when pos <= 0, do: {-pos, abs(vel)}
  defp bounce(pos, vel, max) when pos >= max, do: {2 * max - pos, -abs(vel)}
  defp bounce(pos, vel, _max), do: {pos, vel}
end
