using Game2048
using BenchmarkTools

@benchmark move(board, LEFT) setup=(board=rand(UInt64))

@benchmark move(board, left) setup=(board=rand(UInt64))
@benchmark move(board, right) setup=(board=rand(UInt64))
@benchmark move(board, up) setup=(board=rand(UInt64))
@benchmark move(board, down) setup=(board=rand(UInt64))
