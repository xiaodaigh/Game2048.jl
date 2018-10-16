#in this model getting to 128 is a win to see if the model can be made learn to get to 128
using StatsBase, Flux, JLD2, FileIO#, BSON
include("2048_fn.jl")

# using CUDANative
# CUDANative.device!(1)
# if true
policy = Flux.Chain(
  Conv((2,2), 1=>128, relu)
   ,Conv((2,2), 128=>128, relu)
   ,x -> reshape(x, :, size(x,4))
   ,IdentitySkip(Dense(512, 512), relu)
   ,Dense(512, 4, relu)
  ) |> gpu
# else
#   @load "policy.jld2" policy
# end

const target = 256

@time training_sample = cat((init_game() .|> Float64 for i=1:1_000)..., dims=4) |> gpu
@time policy(training_sample)

#loss(x, (move, reward)) = -reward*log(policy(init)[move .== DIRS][1] + eps(Float64)) |> gpu
loss(x, y) = sum(Flux.logitcrossentropy(policy(x),y)) |> gpu

opt=ADAM(Flux.params(policy))

@time res = policy(training_sample)

agrid = init_game()

function simulate_game_on_policy(policy, lim)
  agrid = init_game()
  init = copy(agrid)
  rewards = Int[]
  seq = Symbol[]
  carts = CartesianIndex{2}[]
  tfs = Int[]
  #policy_cpu = policy |> cpu
  ok = true
  while ok & (maximum(agrid) < lim)
    sample_weight = reshape(softmax(Tracker.data(policy(reshape(Float64.(agrid),4,4,1,1)))),4)
    #sampled_move = sample(DIRS, Weights(sample_weight), 4, replace=false)
    sampled_move = DIRS[sortperm(sample_weight, rev = true)]
    (agrid, ok, move, cart, tf, reward) = simulate_move!(agrid, sampled_move)
    push!(seq, move)
    push!(rewards, reward)
    push!(carts, cart)
    push!(tfs, tf)
  end
  (init, agrid, seq, carts, tfs, rewards)
end

# from my experiment can see that getting to 512 is about 50 harder than 256 using random play
@time (init, fnl, seq, carts, tfs, rewards) = simulate_game_on_policy(policy, Inf); display(fnl)

function convert_to_training_sample_target(init, seq, carts, tfs, rewards)
  reward_disc_rate = 0.99
  agrid = copy(init)
  rewards_real = Float64.(rewards)
  achieved_target = rewards .>= target
  if any(achieved_target)
    rewards_real[achieved_target] = rewards_real[achieved_target] / target
    rewards_real[.!achieved_target] .= 0.0
  else
    rewards_real[.!achieved_target] .= 0.0
    rewards_real[end] = -1.0
  end

  discr = discounted_policy_rewards(rewards_real, reward_disc_rate)

    fnlX = Array{Float64,4}(undef, 4, 4, 1, 8(length(discr)-1))
    fnlY = Array{Float64,2}(undef, 4, 8(length(discr)-1))

  for (i, move, cart, tf, reward) in zip(1:length(discr), seq, carts, tfs, discr)
    if i < length(discr)
      (rotated_grids, rotated_moves) = rotations(copy(agrid), move)
      X = Float64.(cat(reshape.(rotated_grids,4,4,1,1)..., dims=4))
      Y = Flux.onehotbatch(rotated_moves, DIRS).*reward
      fnlX[:,:,:,(1:8).+ 8(i-1)] = X
      fnlY[:,(1:8).+ 8(i-1)] = Y
      replay_move!(agrid, move, cart, tf)
    end
  end
  (fnlX, fnlY)
end

@time res = convert_to_training_sample_target(init, seq, carts, tfs, rewards)

# convert to tensor for training

agrid = res[1][1]
bgrid = res[2][1]

# function train_sample_batch(policy, batch_size)
#   res_vec = Tuple{Array{Int,2}, Tuple{Symbol, Float64}}[]
#   while length(res_vec) < batch_size
#     (init, _, seq, cart, tf, reward) = simulate_game_on_policy(policy)
#     res = convert_to_training_sample_target(init, seq, cart, tf, reward)
#     append!(res_vec, res)
#   end
#   res_vec
# end
# @time train_sample_batch(policy, 2048)

function train_sample_batch_target(policy)
  res_vec = Tuple{Array{Float64,4}, Array{Float64,2}}[]
  foundtarget = false
  i = 0
  while (!foundtarget) | (length(res_vec) < 18)
    i = i + 1
    (init, _, seq, cart, tf, reward) = simulate_game_on_policy(policy, Inf)
    foundtarget = any(reward .>= target)
    res = convert_to_training_sample_target(init, seq, cart, tf, reward)
    push!(res_vec, res)
  end
  println(i)
  res_vec
end

@time res = train_sample_batch_target(policy)

res_vec = train_sample_batch_target(policy)

max_prob = 0.25
i = 0
while true
  global max_prob, i
  #res_vec = train_sample_batch(policy, 20480)
  res_vec = train_sample_batch_target(policy)

  # pb2 = findmax([policy(r[1]) |> Tracker.data |> maximum for r in res_vec])
  # best_one = res_vec[pb2[2]][1]
  # vm = valid_moves(best_one)
  # best_move = DIRS[findmax(policy(best_one) |> Tracker.data)[2]]
  # if any(best_move .== vm) #& (pb2[1] > max_prob)
  #   pb = findmax(policy(best_one) |> Tracker.data)
  #   display("*********************************")
  #   display(best_one)
  #   display((pb[1], DIRS[pb[2]]))
  #   display(Dict(zip(DIRS, policy(best_one) |> Tracker.data)))
  #   display(avg_rewards_next_move(best_one, 100))
  #   max_prob = pb[1]
  # end23
  @time Flux.train!(loss, res_vec, opt)
  @save "policy.jld2" policy
  i = i + 1
  println("************************done this many $i")
  # if any(best_move .== vm) #& (pb2[1] > max_prob)
  #   display(Dict(zip(DIRS, policy(best_one) |> Tracker.data)))
  #   #display((pb[1], DIRS[pb[2]]))
  #   max_prob = pb[1]
  # end
  display(simulate_game_on_policy(policy,Inf)[2])
end

function abc(n)
  [maximum(simulate_game_on_policy(policy_cpu,Inf)[2]) for i=1:n] |>
    countmap
end

policy_cpu = policy |> cpu

@time abc(1)
@time abc(100)

countmap([maximum(simulate_game()[2]) for i=1:1000])

params(policy)
