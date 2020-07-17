module Game2048

include("gamesim/move-up.jl")
include("gamesim/move-board.jl")
include("gamesim/sim-game.jl")
# include("gamesim/play_game_with_policy.jl")

include("bitboard/make_lookups.jl")
include("bitboard/bitboard.jl")

# include("attempts2020/5_policy_gradient.jl")
end # module
