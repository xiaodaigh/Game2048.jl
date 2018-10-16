# this is the 2nd attempt; in this attempt I will try use MCTS and gradients
using StatsBase, DataFrames, Flux, JLD2, Plots
include("2048_fn.jl")

model = Flux.Chain(
  Dense(14*16+4, 128, relu),
  Dense(128, 64, relu),
  Dense(64, 32, relu),
  Dense(32, 1, relu));

loss(x,y) = sum((model(x) .- y).^2)
opt = ADAM(params(model))

# play one game to see how it goes
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
