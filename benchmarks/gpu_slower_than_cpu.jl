# in this attempt, I shall play a set of games with the policy and move the policy using
# the data
using Game2048
using Flux, CUDA
CUDA.allowscalar(false)

policy = Chain(
    Conv((2,2), 1 => 256, relu),
    Conv((2,2), 256 => 128, relu),
    Conv((2,2), 128 => 64, relu),
    flatten,
    Dense(64, 4),
    softmax
) |> gpu

board = initboard()

makeinput(board)  = reshape(board, 4, 4, 1, 1)

cb = cu(Float32.(board) |> makeinput)

using BenchmarkTools
@benchmark policy(cb)
# BenchmarkTools.Trial:
#   memory estimate:  60.33 KiB
#   allocs estimate:  1421
#   --------------
#   minimum time:     418.799 μs (0.00% GC)
#   median time:      470.701 μs (0.00% GC)
#   mean time:        520.493 μs (2.57% GC)
#   maximum time:     36.679 ms (43.01% GC)
#   --------------
#   samples:          9507
#   evals/sample:     1

policy_cpu = Chain(
    Conv((2,2), 1 => 256, relu),
    Conv((2,2), 256 => 128, relu),
    Conv((2,2), 128 => 64, relu),
    flatten,
    Dense(64, 4),
    softmax
)

board = initboard()
fb = Float32.(board) |> makeinput
@benchmark policy_cpu(fb)
# BenchmarkTools.Trial:
#   memory estimate:  153.36 KiB
#   allocs estimate:  211
#   --------------
#   minimum time:     232.399 μs (0.00% GC)
#   median time:      295.501 μs (0.00% GC)
#   mean time:        310.653 μs (2.14% GC)
#   maximum time:     4.700 ms (91.46% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1