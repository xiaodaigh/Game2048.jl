using StatsBase, DataFrames, Flux
include("2048_fn.jl")

using Flux
model = Flux.Chain(
  Dense(14*16+4, 128, relu),
  Dense(128, 64, relu),
  Dense(64, 32, relu),
  Dense(32, 1, relu));

loss(x,y) = sum((model(x) .- y).^2)
opt = ADAM(params(model))

ϵ = 1
@time for i=1:1000
  global ϵ
  ϵ -= 0.0001
  simulate_one_game_and_train!(model, opt, ϵ)
  if i % 100 == 0
    println("epsilon: $ϵ")
    init_grid = init_game()
    res = simulate_game!(init_grid, model, 0)
    display(res[2])
    assess_model(model)
  end
end

using JLD2
@save "no_neg_model.jld2" model

# play one game to see how it goes
function assess_model(model)
  init_grid = init_game()
  @time (init_grid, fnl, seq, cart, tf, reward) = simulate_game!(init_grid, model, 0.5)

  # obtain the discounted rewards
  y = discounted_rewards(reward, 0.99)[1:end-1];

  # score every move using  model
  updated_model = [Tracker.data(model(grid_move_to_feature(sim_seq(init_grid, seq[1:i+1], cart[1:i+1], tf[1:i+1]), seq[i])))[1] for i=1:length(seq)-1]
  #plot(cumsum(reward))
  plot(updated_model, label="model")
  plot!(y, label="discounted rewards")
end

assess_model(model)
