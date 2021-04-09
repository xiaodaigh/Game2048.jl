using Game2048
using Game2048: bitboard_to_array, count0, Bitboard
using BenchmarkTools
using StatsBase: countmap
using DataStructures


using Flux
# play 2048 by lookahead

value = Chain(
    board -> Float32.(bitboard_to_array(board)),
    x -> reshape(x, 4, 4, 1, 1),
    Conv((2,2), 1=>16),
    Conv((2,2), 16=>16),
    Conv((2,2), 16=>16),
    x -> reshape(x, 16),
    Dense(16, 1, exp),
    first
)

board = initbboard()
