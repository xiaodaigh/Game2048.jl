using Game2048
using BenchmarkTools
using StatsBase


board = initboard()
move!(board, left)


@time res = simulate_games(10_000);
res
@time mean(res)
@time extrema(res)

@benchmark simulate_game()