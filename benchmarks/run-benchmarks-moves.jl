# cd("c:/git/Game2048/benchmarks/")

include("move_combine_then_compact.jl")
include("move_ifs.jl")
include("move-loop.jl")
include("move-loop2.jl")
include("move_lookup.jl")

# generate all possible combinations
const VALS = Int8.(1:10)

function gen_all_comb()
    all_comb = Iterators.product([VALS for i in 1:4]...) |> collect ;
    all_comb = [[v...] for v in all_comb];
    all_comb
end

function test(all_comb)
    for v_orig in all_comb
        v_ifs = move_ifs!(copy(v_orig))
        v_combine = move_combine_compact!(copy(v_orig))
        v_loop = move_loop!(copy(v_orig))
        v_loop2 = move_loop2!(copy(v_orig))
        v_lookup = move_lookup!(copy(v_orig))

        if v_combine != v_ifs
            println("wrong ifs")
            println(v_orig)
            println(v_combine)
            println(v_ifs)
        end

        if v_combine != v_loop
            println("wrong loop")
            println(v_orig)
            println(v_combine)
            println(v_loop)
        end

        # if v_combine != v_lookup
        #     println("wrong lookup")
        #     println(v_orig)
        #     println(v_combine)
        #     println(v_lookup)
        # end

        # if v_combine != v_loop2
        #     println("wrong loop2")
        #     println(v_orig)
        #     println(v_combine)
        #     println(v_loop2)
        # end
    end
end

@time test(gen_all_comb())

using BenchmarkTools
# CONCLUSION: they all roughly perform the same so prefer the simpler implementation

@benchmark move_combine_compact!.(all_comb)  setup=(all_comb = gen_all_comb())
# BenchmarkTools.Trial:
#   memory estimate:  78.25 KiB
#   allocs estimate:  3
#   --------------
#   minimum time:     52.100 μs (0.00% GC)
#   median time:      66.101 μs (0.00% GC)
#   mean time:        74.256 μs (3.74% GC)
#   maximum time:     4.943 ms (97.62% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1
@benchmark move_ifs!.(all_comb)  setup=(all_comb = gen_all_comb())
# BenchmarkTools.Trial:
#   memory estimate:  78.25 KiB
#   allocs estimate:  3
#   --------------
#   minimum time:     50.900 μs (0.00% GC)
#   median time:      65.799 μs (0.00% GC)
#   mean time:        74.563 μs (3.42% GC)
#   maximum time:     2.497 ms (93.35% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1
@benchmark move_loop!.(all_comb)  setup=(all_comb = gen_all_comb())
# BenchmarkTools.Trial:
#   memory estimate:  78.25 KiB
#   allocs estimate:  3
#   --------------
#   minimum time:     50.900 μs (0.00% GC)
#   median time:      65.799 μs (0.00% GC)
#   mean time:        74.563 μs (3.42% GC)
#   maximum time:     2.497 ms (93.35% GC)
#   --------------
#   samples:          10000
#   evals/sample:     1