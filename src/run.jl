include("2048_fn.jl")
using BenchmarkTools
@benchmark simulate_game()
