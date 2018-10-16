const DIRS = [:left, :right, :up, :down]
const VALS = vcat(0,[(2).^(1:13)...])
using StatsBase, DataFrames, Flux, Plots, JLD2, FileIO, BSON, Random

function grid_to_feature(grid)
    vec(Flux.onehotbatch(vec(grid),VALS))
end

policy = Flux.Chain(
  grid_to_feature,
  Dense(16*14, 128, relu),
  Dense(128, 4, relu),
  softmax
  )

loss(x, (move, reward)) = -reward*policy(x)[move .== DIRS][1]
opt=ADAM(Flux.params(policy))

@load "res_vec.jld2" res_vec

Random.seed!(0)
for i =1:length(res_vec)
  println(i)
  Flux.train!(loss, res_vec[i:i], opt)
end

polires_vec[800]

loss(res_vec[870]...)

Flux.crossentropy(policy(res_vec[869][1]), Flux.onehot(:up,DIRS))



policy(res_vec[869][1])

Flux.onehot(:up,DIRS)

Flux.crossentropy([false, true, false, false], [1.0, 0.0, 0.0, 0.0] )

Flux.crossentropy([1.0, 0.0,0.0,0.0], [0.0, 1.0, 0.0, 0.0])

-reward*policy(res_vec[1][1])[:left .== DIRS]
