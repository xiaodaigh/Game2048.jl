# Game2048.jl

Simulation of the game 2048 in Julia and trying to do some RL

## The environment

I did not use any RL environment framework. But here's how you can play with it.

````julia
using Game2048: initbboard, add_tile, left, right, up, down

# obtain a new board with 2 tiles populated
board = initbboard()

# you can move left right up or down
new_board = move(board, left)

if new_board != board
    # this will add a new tile on the board
    new_board = add_tile(new_board)
end
````



