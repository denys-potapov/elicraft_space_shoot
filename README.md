# SpaceShoot

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix


world:

  init 
    chooose_background(world, background1)
    create(player)
    create_variable(score, 0)
    create_variable(speed, 0)

  handle_call(tick)
    every(1 second)
      create(Apple)

  
Player

  init
    select_costume (?) sprite
    add costumes
    move(120)
  
  handle_call(tick, stat pressed)
    if key_pressed (left) 
      move_left(1)
    if key_pressed (right)
      move_right(1)
  
Apple

  init
    select_costume (?) sprite
    move top (random)

  handle_call(tick)
    move_bottom 1
  if touches ground
    delete
  if touhes player
    increase score 1
    delete

Multiaple
  
  init
      add_costumne apple = 1, pizza = 2, bomba = 3
      вибрати_випадковий костюм
      move top (random)  

  handle_call(tick, )
    move_bottom speed
    if touches ground
      delete
    if touhes player
      якщо костюм
      яблоко -> 
        increase score 1 (send world)
      піца ->
        increase score 2
      бомба -
        dekreacse score 5
      delete
      
  see forward smth
      
      
  def handle_call({:tick, pressed_keys}, _from, state) do
    if left in pressed_keys
      new_state = %{state | x: state.x - 1}
    if right in pressed_keys
      new_state = %{state | x: state.x + 1}
    {:reply, new_state, new_state}
  end
