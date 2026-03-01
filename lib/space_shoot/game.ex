defmodule SpaceShoot.Game do
  @moduledoc """
  Game state and per-tick update logic for SpaceShoot.
  """

  @canvas_width 800
  @canvas_height 600
  @player_speed 5.0
  @bullet_speed 7.0
  @enemy_bullet_speed 4.0
  @explosion_frame_ticks 5
  @bullet_half_width 8

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
        position: %{x: 400.0, y: 500.0},
        size: %{w: 32, h: 32},
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
        position: %{x: offset_x + col * @enemy_spacing_x, y: 40.0 + row * @enemy_spacing_y},
        size: %{w: 32, h: 32},
        sprite: ship_sprite(rem(row, 4), 1),
        rotation: -:math.pi() / 2,
        health: :alive
      }
    end
  end

  # --- Input ---

  def key_down(state, " ") do
    player = state.player

    bullet = %{
      position: %{
        x: player.position.x + player.size.w / 2 - @bullet_half_width,
        y: player.position.y
      },
      size: %{w: 16, h: 16},
      sprite: @bullet_sprite,
      rotation: 0.0,
      velocity: %{x: 0.0, y: -@bullet_speed},
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
    |> move_player()
    |> move_enemies()
    |> maybe_enemy_shoot()
    |> move_bullets()
    |> remove_offscreen_bullets()
    |> check_bullet_hits()
    |> animate_explosions()
  end

  # --- Move Player ---

  defp move_player(state) do
    keys = state.player.input
    %{x: dx, y: dy} = velocity_from_keys(keys)
    pos = state.player.position
    size = state.player.size

    new_x = clamp(pos.x + dx, 0.0, @canvas_width - size.w)
    new_y = clamp(pos.y + dy, 0.0, @canvas_height - size.h)

    put_in(state.player.position, %{x: new_x, y: new_y})
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

    %{x: dx, y: dy}
  end

  # --- Move Enemies ---

  defp move_enemies(state) do
    dx = if state.enemy_dir == :left, do: -@enemy_speed, else: @enemy_speed

    if enemies_hit_edge?(state.enemies, state.enemy_dir, dx) do
      new_dir = if state.enemy_dir == :left, do: :right, else: :left
      %{state | enemies: drop_enemies(state.enemies), enemy_dir: new_dir}
    else
      %{state | enemies: shift_enemies(state.enemies, dx)}
    end
  end

  defp enemies_hit_edge?(enemies, direction, dx) do
    Enum.any?(enemies, fn e ->
      case direction do
        :left -> e.position.x + dx <= 0
        :right -> e.position.x + dx + e.size.w >= @canvas_width
      end
    end)
  end

  defp drop_enemies(enemies) do
    Enum.map(enemies, fn e ->
      put_in(e.position.y, e.position.y + @enemy_drop)
    end)
  end

  defp shift_enemies(enemies, dx) do
    Enum.map(enemies, fn e ->
      put_in(e.position.x, e.position.x + dx)
    end)
  end

  # --- Maybe Enemy Shoot ---

  defp maybe_enemy_shoot(state) do
    flying_count = Enum.count(state.bullets, &(&1.owner == :enemy))

    if flying_count >= @max_enemy_bullets do
      state
    else
      shooters = bottom_enemies(state.enemies)

      new_bullets =
        Enum.reduce(shooters, [], fn enemy, acc ->
          if :rand.uniform(@enemy_fire_chance) == 1 and
               flying_count + length(acc) < @max_enemy_bullets do
            bullet = %{
              position: %{
                x: enemy.position.x + enemy.size.w / 2 - @bullet_half_width,
                y: enemy.position.y + enemy.size.h
              },
              size: %{w: 16, h: 16},
              sprite: @bullet_sprite,
              rotation: :math.pi(),
              velocity: %{x: 0.0, y: @enemy_bullet_speed},
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
    |> Enum.sort_by(fn e -> -e.position.y end)
    |> Enum.uniq_by(fn e -> round(e.position.x) end)
  end

  # --- Move Bullets ---

  defp move_bullets(state) do
    bullets =
      Enum.map(state.bullets, fn b ->
        if Map.has_key?(b, :velocity) do
          %{b | position: %{x: b.position.x + b.velocity.x, y: b.position.y + b.velocity.y}}
        else
          b
        end
      end)

    %{state | bullets: bullets}
  end

  # --- Remove Offscreen Bullets ---

  defp remove_offscreen_bullets(state) do
    {kept, explosions} =
      Enum.reduce(state.bullets, {[], []}, fn b, {kept, exps} ->
        cond do
          b.position.y <= 0 -> {kept, [explode(b) | exps]}
          b.position.y + b.size.h >= @canvas_height -> {kept, [explode(b) | exps]}
          true -> {[b | kept], exps}
        end
      end)

    %{state | bullets: Enum.reverse(kept), explosions: state.explosions ++ explosions}
  end

  # --- Check Bullet Hits ---

  defp check_bullet_hits(state) do
    {player_bullets, enemy_bullets} = Enum.split_with(state.bullets, &(&1.owner == :player))

    {surviving_player_bullets, enemies, hit_explosions} =
      resolve_player_bullet_hits(player_bullets, state.enemies)

    {surviving_enemy_bullets, player_hit_explosions} =
      resolve_enemy_bullet_hits(enemy_bullets, state.player)

    %{
      state
      | bullets: surviving_player_bullets ++ surviving_enemy_bullets,
        enemies: enemies,
        explosions: state.explosions ++ hit_explosions ++ player_hit_explosions
    }
  end

  defp resolve_player_bullet_hits(bullets, enemies) do
    Enum.reduce(bullets, {[], enemies, []}, fn bullet, {kept, es, exps} ->
      case Enum.find_index(es, &rects_overlap?(bullet, &1)) do
        nil ->
          {[bullet | kept], es, exps}

        hit_index ->
          hit_enemy = Enum.at(es, hit_index)
          {kept, List.delete_at(es, hit_index), [explode(bullet), explode(hit_enemy) | exps]}
      end
    end)
  end

  defp resolve_enemy_bullet_hits(bullets, player) do
    Enum.reduce(bullets, {[], []}, fn bullet, {kept, exps} ->
      if rects_overlap?(bullet, player) do
        {kept, [explode(bullet) | exps]}
      else
        {[bullet | kept], exps}
      end
    end)
  end

  defp rects_overlap?(a, b) do
    a.position.x < b.position.x + b.size.w and
      a.position.x + a.size.w > b.position.x and
      a.position.y < b.position.y + b.size.h and
      a.position.y + a.size.h > b.position.y
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

  defp animate_explosions(state) do
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
    all = [state.player | state.enemies] ++ state.bullets ++ state.explosions
    Enum.map(all, &sprite_to_render/1)
  end

  defp sprite_to_render(entity) do
    %{
      x: round(entity.position.x),
      y: round(entity.position.y),
      width: entity.size.w,
      height: entity.size.h,
      rotation: Map.get(entity, :rotation, 0.0),
      image: entity.sprite.image,
      sx: entity.sprite.sx,
      sy: entity.sprite.sy,
      sw: entity.sprite.sw,
      sh: entity.sprite.sh
    }
  end

  # --- Helpers ---

  defp clamp(value, lower, upper) do
    value |> max(lower) |> min(upper)
  end
end
