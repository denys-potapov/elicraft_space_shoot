defmodule SpaceShoot.Game do
  @moduledoc """
  Game state and tick logic using component-based entities.

  Entities are plain maps. Components are optional keys:
    :position, :size, :sprite, :rotation, :velocity,
    :health, :owner, :explosion, :input
  Systems pattern-match on component presence.
  """

  @canvas_width 800
  @canvas_height 600
  @player_speed 5.0
  @bullet_speed 7.0
  @enemy_bullet_speed 4.0
  @explosion_frame_ticks 5

  # Spritesheet layout: tile size + 1px gap between tiles
  defp ship_sprite(col, row) do
    %{image: "shmup/ships.png", sx: col * 33, sy: row * 33, sw: 32, sh: 32}
  end

  @bullet_sprite %{image: "shmup/tiles.png", sx: 1 * 17, sy: 1 * 17, sw: 16, sh: 16}
  @explosion_sprites [
    %{image: "shmup/tiles.png", sx: 0 * 17, sy: 0 * 17, sw: 16, sh: 16},
    %{image: "shmup/tiles.png", sx: 1 * 17, sy: 0 * 17, sw: 16, sh: 16}
  ]

  @enemy_cols 11
  @enemy_rows 5
  @enemy_spacing_x 48
  @enemy_spacing_y 40
  @enemy_speed 1.0
  @enemy_drop 20.0
  @enemy_fire_chance 100
  @max_enemy_bullets 3

  # --- State ---

  def initial_state do
    %{
      player: %{
        position: {400.0, 500.0},
        size: {32, 32},
        sprite: ship_sprite(0, 0),
        rotation: :math.pi() / 2,
        health: :alive,
        input: MapSet.new()
      },
      enemies: build_enemies(),
      enemy_dir: :left,
      bullets: [],
      explosions: []
    }
  end

  defp build_enemies do
    offset_x = (@canvas_width - @enemy_cols * @enemy_spacing_x) / 2

    for row <- 0..(@enemy_rows - 1), col <- 0..(@enemy_cols - 1) do
      %{
        position: {offset_x + col * @enemy_spacing_x, 40.0 + row * @enemy_spacing_y},
        size: {32, 32},
        sprite: ship_sprite(rem(row, 4), 1),
        rotation: -:math.pi() / 2,
        health: :alive
      }
    end
  end

  # --- Input ---

  def key_down(state, " ") do
    {px, py} = state.player.position
    {pw, _ph} = state.player.size

    bullet = %{
      position: {px + pw / 2 - 8, py},
      size: {16, 16},
      sprite: @bullet_sprite,
      rotation: 0.0,
      velocity: {0.0, -@bullet_speed},
      owner: :player
    }

    %{state | bullets: [bullet | state.bullets]}
  end

  def key_down(state, key) when key in ~w(ArrowUp ArrowDown ArrowLeft ArrowRight) do
    put_in(state.player.input, MapSet.put(state.player.input, key))
  end

  def key_down(state, _key), do: state

  def key_up(state, key) do
    put_in(state.player.input, MapSet.delete(state.player.input, key))
  end

  # --- Tick ---

  def tick(state) do
    state
    |> input_system()
    |> formation_system()
    |> enemy_fire_system()
    |> movement_system()
    |> boundary_system()
    |> collision_system()
    |> explosion_system()
  end

  # --- InputSystem ---

  defp input_system(state) do
    keys = state.player.input
    {dx, dy} = velocity_from_keys(keys)
    {px, py} = state.player.position
    {pw, ph} = state.player.size

    new_x = clamp(px + dx, 0.0, @canvas_width - pw)
    new_y = clamp(py + dy, 0.0, @canvas_height - ph)

    put_in(state.player.position, {new_x, new_y})
  end

  defp velocity_from_keys(keys) do
    dx =
      cond do
        MapSet.member?(keys, "ArrowLeft") and MapSet.member?(keys, "ArrowRight") -> 0.0
        MapSet.member?(keys, "ArrowLeft") -> -@player_speed
        MapSet.member?(keys, "ArrowRight") -> @player_speed
        true -> 0.0
      end

    dy =
      cond do
        MapSet.member?(keys, "ArrowUp") and MapSet.member?(keys, "ArrowDown") -> 0.0
        MapSet.member?(keys, "ArrowUp") -> -@player_speed
        MapSet.member?(keys, "ArrowDown") -> @player_speed
        true -> 0.0
      end

    {dx, dy}
  end

  # --- FormationSystem ---

  defp formation_system(state) do
    dx = if state.enemy_dir == :left, do: -@enemy_speed, else: @enemy_speed

    hit_edge? =
      Enum.any?(state.enemies, fn e ->
        {ex, _ey} = e.position
        {ew, _eh} = e.size

        case state.enemy_dir do
          :left -> ex + dx <= 0
          :right -> ex + dx + ew >= @canvas_width
        end
      end)

    if hit_edge? do
      enemies =
        Enum.map(state.enemies, fn e ->
          {ex, ey} = e.position
          %{e | position: {ex, ey + @enemy_drop}}
        end)

      new_dir = if state.enemy_dir == :left, do: :right, else: :left
      %{state | enemies: enemies, enemy_dir: new_dir}
    else
      enemies =
        Enum.map(state.enemies, fn e ->
          {ex, ey} = e.position
          %{e | position: {ex + dx, ey}}
        end)

      %{state | enemies: enemies}
    end
  end

  # --- EnemyFireSystem ---

  defp enemy_fire_system(state) do
    flying_count = Enum.count(state.bullets, &(&1.owner == :enemy))

    if flying_count >= @max_enemy_bullets do
      state
    else
      shooters = bottom_enemies(state.enemies)

      new_bullets =
        Enum.reduce(shooters, [], fn enemy, acc ->
          if :rand.uniform(@enemy_fire_chance) == 1 and flying_count + length(acc) < @max_enemy_bullets do
            {ex, ey} = enemy.position
            {ew, eh} = enemy.size

            bullet = %{
              position: {ex + ew / 2 - 8, ey + eh},
              size: {16, 16},
              sprite: @bullet_sprite,
              rotation: :math.pi(),
              velocity: {0.0, @enemy_bullet_speed},
              owner: :enemy
            }

            [bullet | acc]
          else
            acc
          end
        end)

      %{state | bullets: new_bullets ++ state.bullets}
    end
  end

  defp bottom_enemies(enemies) do
    enemies
    |> Enum.group_by(fn e -> round(elem(e.position, 0)) end)
    |> Enum.map(fn {_col, col_enemies} ->
      Enum.max_by(col_enemies, fn e -> elem(e.position, 1) end)
    end)
  end

  # --- MovementSystem ---

  defp movement_system(state) do
    bullets =
      Enum.map(state.bullets, fn
        %{velocity: {vx, vy}, position: {x, y}} = b ->
          %{b | position: {x + vx, y + vy}}

        b ->
          b
      end)

    %{state | bullets: bullets}
  end

  # --- BoundarySystem ---

  defp boundary_system(state) do
    {bullets, new_explosions} =
      Enum.reduce(state.bullets, {[], []}, fn b, {bs, exps} ->
        {_x, y} = b.position
        {_w, h} = b.size

        cond do
          y <= 0 -> {bs, [explode(b) | exps]}
          y + h >= @canvas_height -> {bs, [explode(b) | exps]}
          true -> {[b | bs], exps}
        end
      end)

    %{state | bullets: Enum.reverse(bullets), explosions: state.explosions ++ new_explosions}
  end

  # --- CollisionSystem ---

  defp collision_system(state) do
    {bullets, enemies, explosions} =
      Enum.reduce(state.bullets, {[], state.enemies, []}, fn bullet, {bs, es, exps} ->
        case bullet.owner do
          :player ->
            case find_hit_enemy(bullet, es) do
              nil ->
                {[bullet | bs], es, exps}

              hit_index ->
                hit_enemy = Enum.at(es, hit_index)
                new_enemies = List.delete_at(es, hit_index)
                {bs, new_enemies, [explode(bullet), explode(hit_enemy) | exps]}
            end

          :enemy ->
            if Map.has_key?(state.player, :health) and rects_overlap?(bullet, state.player) do
              {bs, es, [explode(bullet) | exps]}
            else
              {[bullet | bs], es, exps}
            end
        end
      end)

    %{state | bullets: Enum.reverse(bullets), enemies: enemies, explosions: state.explosions ++ explosions}
  end

  defp find_hit_enemy(bullet, enemies) do
    Enum.find_index(enemies, fn e ->
      Map.has_key?(e, :health) and rects_overlap?(bullet, e)
    end)
  end

  defp rects_overlap?(a, b) do
    {ax, ay} = a.position
    {aw, ah} = a.size
    {bx, by} = b.position
    {bw, bh} = b.size

    ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
  end

  # --- Explosions ---

  defp explode(entity) do
    %{
      position: entity.position,
      size: entity.size,
      sprite: hd(@explosion_sprites),
      rotation: Map.get(entity, :rotation, 0.0),
      explosion: %{frame: 0, timer: 0, sprites: @explosion_sprites}
    }
  end

  defp explosion_system(state) do
    explosions =
      state.explosions
      |> Enum.map(&tick_explosion/1)
      |> Enum.reject(&is_nil/1)

    %{state | explosions: explosions}
  end

  defp tick_explosion(%{explosion: exp} = e) do
    new_timer = exp.timer + 1

    if new_timer >= @explosion_frame_ticks do
      new_frame = exp.frame + 1

      if new_frame >= length(exp.sprites) do
        nil
      else
        new_exp = %{exp | frame: new_frame, timer: 0}
        %{e | explosion: new_exp, sprite: Enum.at(exp.sprites, new_frame)}
      end
    else
      %{e | explosion: %{exp | timer: new_timer}}
    end
  end

  # --- Rendering ---

  def render_sprites(state) do
    all =
      [state.player | state.enemies] ++ state.bullets ++ state.explosions

    Enum.map(all, &sprite_to_render/1)
  end

  defp sprite_to_render(entity) do
    {x, y} = entity.position
    {w, h} = entity.size

    %{
      x: round(x),
      y: round(y),
      width: w,
      height: h,
      rotation: Map.get(entity, :rotation, 0.0),
      image: entity.sprite.image,
      sx: entity.sprite.sx,
      sy: entity.sprite.sy,
      sw: entity.sprite.sw,
      sh: entity.sprite.sh
    }
  end

  # --- Helpers ---

  defp clamp(val, min, max) do
    val |> max(min) |> min(max)
  end
end
