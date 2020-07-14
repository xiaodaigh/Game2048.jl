using Game2048
using Test

@testset "Game2048.jl" begin
    @test true == true
end


board = initboard()
rand_dir = rand((left, right, up, down))
@time move!(board, rand_dir); board