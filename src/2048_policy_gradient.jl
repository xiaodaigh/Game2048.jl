# this is the 2nd attempt; in this attempt I will try use MCTS and gradients
using StatsBase, DataFrames, Flux, Plots, JLD2, FileIO, BSON
include("2048_fn.jl")

struct IdentitySkip
   inner
   activation
end

(m::IdentitySkip)(x) = m.activation.(m.inner(x) .+ x)
IdentitySkip(Dense(128, 128), relu)

policy = Flux.Chain(
  grid_to_feature,
  Dense(16*14, 128, relu),
  IdentitySkip(Dense(128, 128), relu),
  Dense(128, 32, relu),
  IdentitySkip(Dense(32, 32), relu),
  Dense(32, 4),
  softmax
  )

loss(x, (move, reward)) = reward*log(policy(init)[move .== DIRS][1] + eps(Float64))
opt=ADAM(Flux.params(policy))

function simulate_game_on_policy(policy)
  agrid = init_game()
  init = copy(agrid)
  # play according to policy
  vm = valid_moves(agrid)
  rewards = Int[]
  seq = Symbol[]
  carts = CartesianIndex{2}[]
  tfs = Int[]

  while length(vm) > 0
    sample_weight = softmax(Tracker.data(policy(agrid))[indexin(vm, DIRS)])
    sampled_move = sample(vm, Weights(sample_weight))
    (agrid, cart, tf, reward) = simulate_one!(agrid, sampled_move)
    push!(seq, sampled_move)
    push!(rewards, reward)
    push!(carts, cart)
    push!(tfs, tf)
    vm = valid_moves(agrid)
  end
  (init, agrid, seq, carts, tfs, rewards)
end

@time (init, fnl, seq, cart, tf, reward) = simulate_game_on_policy(policy)

function convert_to_training_sample(init, seq, carts, tfs, rewards)
  reward_disc_rate = 0.99
  agrid = copy(init)
  discr = discounted_rewards(rewards, reward_disc_rate)
  #discr = (discr .- StatsBase.mean(discr))./StatsBase.std(discr)

  res_vec = Tuple{Array{Int,2}, Tuple{Symbol, Float64}}[]
  for (move, cart, tf, reward) in zip(seq, carts, tfs, discr)
    (rotated_grids, rotated_moves) = rotations(copy(agrid), move)
    mean_random_reward = avg_disc_reward(agrid, 20, reward_disc_rate)
    repeat_reward = repeat([reward-mean_random_reward], inner=8)
    append!(res_vec, zip(rotated_grids, zip(rotated_moves, repeat_reward)) |> collect)
    replay_move!(agrid, move, cart, tf)
  end
  res_vec
end

@time res = convert_to_training_sample(init, seq, cart, tf, reward)

function train_sample_batch(policy, batch_size)
  res_vec = Tuple{Array{Int,2}, Tuple{Symbol, Float64}}[]
  while length(res_vec) < batch_size
    (init, _, seq, cart, tf, reward) = simulate_game_on_policy(policy)
    res = convert_to_training_sample(init, seq, cart, tf, reward)
    append!(res_vec, res)
  end
  res_vec
end

max_prob = 0.25

while true
  global max_prob
  res_vec = train_sample_batch(policy, 20480)

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
  # end
  @time Flux.train!(loss, res_vec, opt)
  @save "policy.jld2" policy
  # if any(best_move .== vm) #& (pb2[1] > max_prob)
  #   display(Dict(zip(DIRS, policy(best_one) |> Tracker.data)))
  #   #display((pb[1], DIRS[pb[2]]))
  #   max_prob = pb[1]
  # end
  display(simulate_game_on_policy(policy)[2])
end

function abc()
  init = init_game()
  (init, fnl, seq, cart, tf, reward) = simulate_game_on_policy(policy)
  maximum(fnl)
end

policy_max = [abc() for i=1:10000]
random_max = [maximum(simulate_game!(init_game())[2]) for i = 1:10000]

countmap(policy_max)
countmap(random_max)

#nback = Int(round(length(seq)/2, digits=0))
for i = 1:length(seq)-1
  bgrid = sim_seq!(copy(init), seq[1:end-i], cart[1:end-i], tf[1:end-i])
  prob = round.(policy(bgrid) |> Tracker.data, digits=4)
  if all(prob .!= 0.25)
    display(bgrid)
    display(DataFrame(dir = DIRS, prob = prob))
  end
end



Flux.train!(loss, res_vec, opt)
softmax(policy(bgrid))

loss(res_vec[1][1], res_vec[2][2])

loss(init, (:left, 1))

loss2(grid,())reward*Flux.crossentropy(softmax(policy(move)), move .== DIRS)

loss1(grid,(move, reward)) = (grid, move, reward)
loss1(res_vec[1]...)

display(agrid)
display(transpose(agrid))

:left => :up
:right => :down
:up => :left
:down => :right

(agrid, cart, tf, reward) = simulate_one!(agrid, :left)

typeof(cart)

function train1!(policy, critic, policy_loss, critic_loss, opt, opt_critic, n;
  γ = 0.99 # next critic moves downward rate
  )
  for i = 1:n
    agrid = init_game()
    vm = valid_moves(agrid)
    while length(vm) > 0
      # use policy to generate searches
      p = Tracker.data(policy(agrid))[indexin(vm, DIRS)]

      sampled_move = sample(vm, Weights(p))
      (new_grid, _, _, reward) = simulate_one!(copy(agrid), sampled_move)

      # sample a new move for the new_grid
      new_vm = valid_moves(new_grid)

      if length(new_vm) > 0
        p = Tracker.data(policy(new_grid))[indexin(new_vm, DIRS)]
        sampled_next_action = sample(new_vm, Weights(p))

        # evaluate critic at the new location
        discounted_critic_value = γ*Tracker.data(critic((new_grid, sampled_next_action)))[1]
      else
        discounted_critic_value = 0
      end

      # update the critic
      Flux.train!(critic_loss, [((agrid, sampled_move), reward + discounted_critic_value)], opt_critic)

      # now use the updated critic to update to the policy
      best_move_according_to_new_critic = findmax(Dict{Symbol, Float64}((vm1, Tracker.data(critic((agrid, vm1)))[1]) for vm1 in vm))[2]
      Flux.train!(policy_loss, [(agrid, Flux.onehot(best_move_according_to_new_critic, DIRS))], opt)

      agrid = new_grid
      vm = new_vm
    end
    i += 1
    if i % 1000 == 0
      @save "actor_critic_model.jld2" policy critic
      display(agrid)
    end
  end
end

init = init_game()

policy(init)
[critic((init,vm)) for vm in DIRS]
@time train1!(policy, critic, policy_loss, critic_loss, opt, opt_critic, 1_000_000)
policy(init)
critic((init,:left))

(init, fnl, seq, cart, tf, rewards) = simulate_game!(init)

nmovesback = 1
last_grid = sim_seq(init, seq[1:end-nmovesback], cart[1:end-nmovesback], tf[1:end-nmovesback])
display(last_grid)
display(policy(last_grid))
display([(vm, Tracker.data(critic((last_grid, vm)))[1]) for vm in valid_moves(last_grid)])

#manually train this
agrid = copy(last_grid)
vm = valid_moves(agrid)

# use policy to generate searches
p = Tracker.data(policy(agrid))[indexin(vm, DIRS)]

sampled_move = sample(vm, Weights(p))
(new_grid, _, _, reward) = simulate_one!(copy(agrid), sampled_move)

# sample a new move for the new_grid
new_vm = valid_moves(new_grid)

if length(new_vm) > 0
  p = Tracker.data(policy(new_grid))[indexin(new_vm, DIRS)]
  sampled_next_action = sample(new_vm, Weights(p))

  # evaluate critic at the new location
  discounted_critic_value = γ*Tracker.data(critic((new_grid, sampled_next_action)))[1]
else
  discounted_critic_value = 0
end

critic((agrid, :right))
# update the critic
Flux.train!(critic_loss, [((agrid, sampled_move), reward + discounted_critic_value)], opt_critic)
display((critic((agrid, :right))|> Tracker.data, critic((agrid, :left))|>Tracker.data))

# now use the updated critic to update to the policy
best_move_according_to_new_critic = findmax(Dict{Symbol, Float64}((vm1, Tracker.data(critic((agrid, vm1)))[1]) for vm1 in vm))[2]
Flux.train!(policy_loss, [(agrid, Flux.onehot(best_move_according_to_new_critic, DIRS))], opt)

agrid = new_grid
old_grid = copy(new_grid)
display(agrid)
vm = new_vm



critic((init,:left))


agrid = last_grid

vm = valid_moves(agrid)





(init, fnl, seq, cart, tf, reward) = simulate_game!(agrid)

# obtain the last move
last_move = 2
before_last = sim_seq(init, seq[1:end-last_move], cart[1:end-last_move], tf[1:end-last_move])

vm = valid_moves(before_last)
@time avg_rewards_next_move(before_last, 100)

function train_n_games(n, model, opt)
  for i=1:n
    agrid = init_game()

    vm = valid_moves(agrid)
    while length(vm) > 0
      # compute average rewards
      avgr = avg_rewards_next_move(agrid, 100)
      grid_as_features = grid_to_feature(agrid)
      #model(grid_as_features)
      Flux.train!(loss, [(grid_as_features, findmax(avgr)[2])], opt)

      # now choose an action based on the updated policy
      themove = sample(vm, Weights(Tracker.data(model(grid_as_features))[indexin([:left,:up], DIRS)]))
      simulate_one!(agrid, themove)
      vm = valid_moves(agrid)
    end
    println(i)
    display(agrid)

    @save "policy_gradient_model.jld2" model

  end
end

@time train_n_games(1, model, opt)

agrid = init_game()
(init,_,seq,cart, tf,_) = simulate_game!(agrid)

new_grid = sim_seq(init, seq[1:end-2], cart[1:end-2], tf[1:end-2])

model(grid_to_feature(new_grid))
avgr = avg_rewards_next_move(new_grid, 100)
best_move = findmax(avgr)[2]
Flux.@epochs 10000 Flux.train!(loss, [(grid_to_feature(new_grid), Flux.onehot(best_move, DIRS))], opt)
model(grid_to_feature(new_grid))





Float64.(Flux.onehot(best_move, DIRS))

crossentropy(model(grid_to_feature(new_grid)), Float64.(Flux.onehot(best_move, DIRS)))

logloss(model(grid_to_feature(new_grid)), Float64.(Flux.onehot(:up, DIRS)))

grid_to_feature(before_last) |>
  model |>
  Tracker.data

grid_to_feature(before_last) |>
  model |>
  Tracker.data

function assess_model(model)
  init_grid = init_game()
  @time (init_grid, fnl, seq, cart, tf, reward) = simulate_game!(init_grid, model, 0.0)

  # obtain the discounted rewards
  y = discounted_rewards(reward, 0.99)[1:end-1];

  # score every move using  model
  updated_model = [Tracker.data(model(grid_move_to_feature(sim_seq(init_grid, seq[1:i+1], cart[1:i+1], tf[1:i+1]), seq[i])))[1] for i=1:length(seq)-1]
  display(sim_seq(init_grid, seq, cart, tf))
  g = plot(updated_model, label="model")
  plot!(y, label="discounted rewards")
  (init_grid, fnl, seq, cart, tf, reward, g)
end

ϵ = 0.5

model = nothing
@load "no_neg_model.jld2"
model

@time for i=1:10000
  global ϵ
  ϵ -= 0.0001
  simulate_one_game_and_train!(model, opt, ϵ)
  if i % 100 == 0
    @save "no_neg_model.jld2" model;
    println("epsilon: $ϵ")
    init_grid = init_game()
    res = simulate_game!(init_grid, model, 0)
    display(res[2])
    @save "no_neg_model.jld2" model;
  end
end


@time (init, fnl, seq, cart, tf, reward, g) = assess_model(model);
g

last_n_move = length(seq)-20
grid_new = sim_seq(init, seq[1:end-last_n_move], cart[1:end-last_n_move], tf[1:end - last_n_move])
grid_try = copy(grid_new)
display(grid_new)
vm = valid_moves(grid_new)
x = vec(Tracker.data(model(hcat(grid_move_to_feature.([grid_new], vm)...))))
y = x .- minimum(x)


using DataFrames
DataFrame(vm=vm, chosen=vm.== seq[end-last_n_move], x=vec(x),  prob_exp = round.(exp.(y)/sum(exp.(y)),digits=2), prob_square =((y.+1).^2)./sum((y.+1).^2))
