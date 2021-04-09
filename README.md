# Game2048.jl

Simulation of the game 2048 in Julia and trying to do some RL

## The environment

I did not use any RL environment framework. But here's how you can play with it.

````julia
using Game2048: initboard, move!, gen_new_tile!, left, right, up, down

# obtain a new board with 2 tiles populated
board = initboard()

# you can move left right up or down
reward, valid_move = move!(board, left)


if valid_move
    # this will add a new tile on the board
    gen_new_tile!(board)
end
```
