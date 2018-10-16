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

@time simulate_one_game_and_train!(model, opt, 0.9)

init_grid = init_game()
@time (init_grid, fnl, seq, cart, tf, reward) = simulate_game!(init_grid, model, 0.5)

# score every move using untrained model
grid_try = copy(init_grid)
initial_model = [Tracker.data(model(grid_move_to_feature(sim_seq(grid_try, seq[1:i+1], cart[1:i+1], tf[1:i+1]), seq[i])))[1] for i=1:length(seq)-1]

# now fit the model once
x = generate_x_based_on_episode(init_grid, seq, cart, tf);
y = discounted_rewards(reward, 0.99)[1:end-1];
xy = [(x[:,j], y[j]) for j in 1:size(x)[2]]
Flux.@epochs 100 Flux.train!(loss, xy, opt)

updated_model = [Tracker.data(model(grid_move_to_feature(sim_seq(grid_try, seq[1:i+1], cart[1:i+1], tf[1:i+1]), seq[i])))[1] for i=1:length(seq)-1]
using Plots
plot(cumsum(reward))
plot!(updated_model)
plot!(y)
