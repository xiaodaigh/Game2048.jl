using StatsBase, DataFrames, Flux, JLD2, Plots
include("2048_fn.jl")

if false
  model = Flux.Chain(
    Dense(14*16+4, 128, σ),
    Dense(128, 64, σ),
    Dense(64, 32, σ),
    Dense(32, 1, σ));
  ϵ = 1
else
  @load "neg_model.jld2"
  ϵ = 0.64
end

loss(x,y) = sum((model(x) .- y).^2)
opt = ADAM(params(model))

# play one game to see how it goes
function assess_model(model)
  init_grid = init_game()
  @time (init_grid, fnl, seq, cart, tf, reward) = simulate_game!(init_grid, model, 0)
  display(fnl)
  # obtain the discounted rewards
  reward[end-1] -= 20480
  y = Flux.σ.(discounted_rewards(reward, 0.90)[1:end-1]./20480);

  # score every move using  model
  updated_model = [Tracker.data(model(grid_move_to_feature(sim_seq(init_grid, seq[1:i+1], cart[1:i+1], tf[1:i+1]), seq[i])))[1] for i=1:length(seq)-1]
  #plot(cumsum(reward))
  g = plot(updated_model, label="model")
  plot!(y, label="discounted rewards")
  g
end

@time for i=1:1_000_000
  global ϵ
  ϵ *= 0.99999
  simulate_one_game_and_train!(model, opt, ϵ)
  if i % 1000 == 0
    println("epsilon: $ϵ")
    init_grid = init_game()
    res = simulate_game!(init_grid, model, 0)
    display(res[2])
    #assess_model(model)
    @save "neg_model.jld2" model
  end
end

assess_model(model)

init_grid = init_game()
x = Tracker.data(model(hcat(grid_move_to_feature.([init_grid], DIRS)...)))
x = exp.(x .- minimum(x))
println(x ./ sum(x))
