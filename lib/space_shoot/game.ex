defmodule SpaceShoot.Game do
  @moduledoc """
  Game state and tick logic.
  """

  @canvas_width 800
  @canvas_height 600
  @speed 5.0

  def initial_state do
    %{
      keys: MapSet.new(),
      sprites: [
        %{x: 100.0, y: 100.0, image: "logo.svg", width: 64, height: 64}
      ]
    }
  end

  def key_down(state, key) when key in ~w(ArrowUp ArrowDown ArrowLeft ArrowRight) do
    %{state | keys: MapSet.put(state.keys, key)}
  end

  def key_down(state, _key), do: state

  def key_up(state, key) do
    %{state | keys: MapSet.delete(state.keys, key)}
  end

  def tick(state) do
    {dx, dy} = velocity_from_keys(state.keys)
    %{state | sprites: Enum.map(state.sprites, &move_sprite(&1, dx, dy))}
  end

  def render_sprites(state) do
    Enum.map(state.sprites, fn s ->
      %{x: round(s.x), y: round(s.y), image: s.image, width: s.width, height: s.height}
    end)
  end

  defp velocity_from_keys(keys) do
    dx =
      cond do
        MapSet.member?(keys, "ArrowLeft") and MapSet.member?(keys, "ArrowRight") -> 0.0
        MapSet.member?(keys, "ArrowLeft") -> -@speed
        MapSet.member?(keys, "ArrowRight") -> @speed
        true -> 0.0
      end

    dy =
      cond do
        MapSet.member?(keys, "ArrowUp") and MapSet.member?(keys, "ArrowDown") -> 0.0
        MapSet.member?(keys, "ArrowUp") -> -@speed
        MapSet.member?(keys, "ArrowDown") -> @speed
        true -> 0.0
      end

    {dx, dy}
  end

  defp move_sprite(s, dx, dy) do
    new_x = clamp(s.x + dx, 0.0, @canvas_width - s.width)
    new_y = clamp(s.y + dy, 0.0, @canvas_height - s.height)
    %{s | x: new_x, y: new_y}
  end

  defp clamp(val, min, max) do
    val |> max(min) |> min(max)
  end
end
