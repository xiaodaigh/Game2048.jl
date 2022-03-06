export gui_game

using GameZero: rungame

function gui_game()
    path = pathof(Game2048)
    rungame(joinpath(dirname(dirname(path)), "game-zero", "game.jl"))
end