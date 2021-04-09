module Game2048

export Dirs, left, right, up, down, move!, move

@enum Dirs left right up down

include("uint_board/move-up.jl")
# include("gamesim/move-board.jl")
# include("gamesim/sim-game.jl")
# include("gamesim/play_game_with_policy.jl")

# include("identity-skip.jl")

include("rotate-mirror.jl")



include("bitboard/make_lookups.jl")
include("bitboard/bitboard.jl")
include("bitboard/simulate_bb.jl")
# include("bitboard/playahead.jl")
# include("bitboard/fingerprint.jl")

# include("monte-carlo-tree.jl")


# include("attempts2020/5_policy_gradient.jl")
end # module
