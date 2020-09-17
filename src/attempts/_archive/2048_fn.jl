# using StatsBase, DataFrames, JLD2, FileIO

# const DIRS = [:left, :up, :right, :down]
# const VALS = vcat(0,[(2).^(1:13)...])

# rand2_1() = rand() < 0.1 ? 2 : 1
# rand4() = Int8((rand(UInt8) % 4) + 1)

# if false
#     # x = [rand4() for i =1:1_000_000]
#     # using StatsBase
#     # countmap(x)

#     # move left
#     xinc=1
#     xstart=1
#     xend=4

#     # move right
#     xinc=-1
#     xstart=4
#     xend=1
# end
# # a function to simulate the move and return a reward
# function move!(x, xinc, xstart, xend)
#     reward = 0
#     @inbounds for i = xstart:xinc:xend # for each row move the left most piece first #if move_row = 1 then i control the row
#         if x[i] != 0 # if the position is occupied by a number move it
#             # firstly look "behind" to see if there is a number that is the same
#             # this is to deal better with situations like 2 2 4 4
#             @inbounds for k = i+xinc:xinc:xend
#                 if x[k] != 0
#                     if x[k] == x[i]
#                         x[i] += 1
#                         reward += 2^x[i]
#                         x[k] = 0
#                     end
#                     break;
#                 end
#             end
#             # now place it in the first empty slot
#             @inbounds for k = xstart:xinc:i
#                 if x[k] == 0
#                     x[k] = x[i]
#                     x[i] = 0
#                 end
#             end
#         end
#     end
#     (x, reward)
# end

# function move_left!(x)
#     move!(x, 1, 1, 4)
# end

# function move_right!(x)
#     move!(x, -1, 4, 1)
# end

# function move!(grid::Array{T,2}, direction) where T <: Integer
#     reward::Int16 = zero(Int16)
#     if direction == :left
#         for j = 1:4
#             #grid[j,:] .= move_left!(grid[j,:])
#             (tmp, new_reward) = move_left!(@view grid[j,:])
#             reward += new_reward
#         end
#     elseif direction == :right
#         for j = 1:4
#             #grid[j,:] .= move_right!(grid[j,:])
#             (tmp, new_reward) = move_right!(@view grid[j,:])
#             reward += new_reward
#         end
#     elseif direction == :up
#         for j = 1:4
#             #grid[:,j] .= move_left!(grid[:,j])
#             (tmp, new_reward) = move_left!(@view grid[:,j])
#             reward += new_reward
#         end
#     else
#         for j = 1:4
#             #grid[:,j] .= move_right!(grid[:,j])
#             (tmp, new_reward) = move_right!(@view grid[:,j])
#             reward += new_reward
#         end
#     end
#     (grid, reward)
# end

# function has_valid_move(x, direction)
#     if direction == :left
#         xstart = 1
#         xinc = 1
#         xend = 4
#     else
#         xstart = 4
#         xinc = -1
#         xend = 1
#     end
#     ((x[xstart] == 0)  & any(x[xstart+xinc:xinc:xend] .> 0)) |
#     ((x[xstart+xinc] == 0)  & any(x[xstart+2xinc:xinc:xend] .> 0)) |
#     ((x[xstart+2xinc] == 0)  & (x[xend] > 0)) |
#     ((x[xstart] > 0) & (x[xstart] == x[xstart + xinc])) |
#     ((x[xstart+xinc] > 0) & (x[xstart+xinc] == x[xstart+2xinc])) |
#     ((x[xstart+2xinc] > 0) & (x[xstart+2xinc] == x[xend]))
# end

# function valid_moves(grid::Array{T,2}) where T
#     left_has = any([has_valid_move(@view(grid[i,:]), :left) for i=1:4])
#     right_has = any([has_valid_move(@view(grid[i,:]), :right) for i=1:4])
#     up_has = any([has_valid_move(@view(grid[:,i]), :left) for i=1:4])
#     down_has = any([has_valid_move(@view(grid[:,i]), :right) for i=1:4])
#     [:left, :right, :up, :down][[left_has, right_has, up_has, down_has]]
# end

# function simulate_move!(grid)
#     directions = sample(DIRS, 4 , replace = false)
#     for i in 1:3
#         d1 = directions[i]
#         (grid, ok, cart, two_or_four, reward) = simulate_move!(grid, d1)
#         if ok
#            return  (grid, true, d1, cart, two_or_four, reward)
#         end
#     end
#     (grid, ok, cart, two_or_four, reward) = simulate_move!(grid, directions[4])
#     (grid, ok, directions[4], cart, two_or_four, reward)
# end

# function simulate_move!(grid, directions::Array{Symbol,1})
#     for i in 1:3
#         d1 = directions[i]
#         (grid, ok, cart, two_or_four, reward) = simulate_move!(grid, d1)
#         if ok
#            return  (grid, true, d1, cart, two_or_four, reward)
#         end
#     end
#     (grid, ok, cart, two_or_four, reward) = simulate_move!(grid, directions[4])
#     (grid, ok, directions[4], cart, two_or_four, reward)
# end

# # assume no need to check for validate moves
# function simulate_move!(grid, direction::Symbol)
#     tmp_grid = copy(grid)
#     (grid, reward) = move!(grid, direction)
#     if all(tmp_grid .== grid)
#         return (grid, false, CartesianIndex{2}(-1,-1), -1, 0)
#     else
#         cart = rand(findall(grid .== 0)) # randomly choose one empty slot
#         one_or_two = rand2_1()
#         grid[cart] = one_or_two
#         return (grid, true, cart, one_or_two, reward)
#     end
# end

# function simulate_game!(grid, lim)
#     init_grid = copy(grid)
#     seq = Symbol[]::Array{Symbol,1}
#     cartarr = CartesianIndex{2}[]
#     one_or_two_arr = Int8[]
#     reward_vec = Int16[]

#     ok = true

#     while ok
#         (grid, ok1, move, cart, one_or_two, new_reward) = simulate_move!(grid)
#         ok = ok1 & all(grid .< lim)
#         push!(seq, move)
#         push!(cartarr, cart)
#         push!(one_or_two_arr, one_or_two)
#         push!(reward_vec, new_reward)
#     end
#     (init_grid, grid, seq, cartarr, one_or_two_arr, reward_vec)
# end

# function simulate_game()
#     init = init_game()
#     simulate_game!(init, Inf)
# end

# function init_game()
#     grid = zeros(Int8,4,4)
#     grid[rand(1:4),rand(1:4)] = rand2_1()
#     grid[rand(1:4),rand(1:4)] = rand2_1()
#     grid
# end

# function see_which_move_is_better(grid)
#     score = sum(grid)
#     grid_try = similar(grid)
#     res_dict = Dict{Symbol, Float64}()
#     for direction in [:left, :right, :up, :down]
#          res_dict[direction] = StatsBase.mean([see_which_move_is_better!(grid, grid_try, direction) for j=1:100])
#     end
#     res_dict
# end

# function see_which_move_is_better!(grid, grid_try, direction)
#     grid_try .= grid
#     simulate_one!(grid_try, direction)
#     simulate_game!(grid_try)
#     sum(grid_try)
# end

# # simulate n moves ahead
# function simulate_moves_ahead(grid)
#     grid_try = similar(grid)

#     res_dict = Dict{NTuple{9, Symbol}, Float64}()
#     for moves in Iterators.product([DIRS for i = 1:9]...)
#         grid_try .= grid
#         simulate_one!.([grid_try], moves)
#         res_dict[moves] = sum(grid_try)
#     end
#     res_dict
# end

# function simulate_n_games_get_score(n)
#     reward_vec = Int64[]
#     maxcell = Int64[]
#     for i=1:n
#         init = init_game()
#         (init, fnl, seq, cart, tf, reward) = simulate_game!(init);
#         push!(reward_vec, sum(reward))
#         push!(maxcell, maximum(fnl))
#     end
#     (reward_vec,maxcell)
# end

# function simulate_game!(grid, nn, ϵ)
#     init_grid = copy(grid)
#     seq = Symbol[]::Array{Symbol,1}
#     cartarr = CartesianIndex{2}[]
#     two_or_four_arr = Int64[]
#     reward_vec = Int64[]

#     vm = valid_moves(grid)
#     ok = length(vm) > 0

#     while ok
#         if rand() < ϵ
#             move = rand(vm)
#         else
#             prob = Tracker.data.(nn.(grid_move_to_feature.([grid], vm)))
#             x = [aa[1] for aa in prob]
#             x .= x .- minimum(x) .+ 1
#             #x .= exp.(x)
#             x .= x.^2
#             move = sample(vm, Weights(x), 1)[1]
#         end
#         (grid, cart, two_or_four, new_reward) = simulate_one!(grid, move)
#         push!(seq, move)
#         push!(cartarr, cart)
#         push!(two_or_four_arr, two_or_four)
#         push!(reward_vec, new_reward)
#         vm = valid_moves(grid)
#         ok = length(vm) > 0
#     end

#     push!(seq, :stopped)
#     push!(cartarr, CartesianIndex{2}())
#     push!(two_or_four_arr, 0)
#     push!(reward_vec, 0.0)

#     (init_grid, grid, seq, cartarr, two_or_four_arr, reward_vec)
# end

# function simulate_one_game_and_train!(model, opt, ϵ)
#     grid = init_game()
#     (init, fnl, seq, cart, tf, reward) = simulate_game!(grid, model, ϵ)
#     x = generate_x_based_on_episode(init, seq, cart, tf);
#     y = discounted_rewards(reward, 0.99)[1:end-1];
#     xy = [(x[:,j], y[j]) for j in 1:size(x)[2]]
#     Flux.train!(loss, xy, opt);
#     nothing
#     #lxy= loss(x,y)
#     #println(lxy)
#     #lxy
# end

# function train_model_n(n, model, opt, ϵ)
#     for i=1:n
#         ϵ = ϵ * 0.999
#         simulate_one_game_and_train!(model, opt, ϵ)
#         if i % 100 == 0
#             grid = init_game()
#             (init, fnl, seq, cart, tf, reward) = simulate_game!(grid, model, ϵ)
#             x = generate_x_based_on_episode(init, seq, cart, tf);
#             y = discounted_rewards(reward, 0.99)[1:end-1];
#             #display(model(x)[[1,end]])
#     #         @show y[[1,end]]
#     #         display((ϵ, loss(x,y)))
#             println(maximum(fnl))
#         end
#     end
#     @save "model.jld2" model
#     ϵ
# end

# function grid_move_to_feature(grid, move)
#     input = vec(Flux.onehotbatch(vec(grid),VALS))
#     # create the data
#     vcat(input, Flux.onehot(move, DIRS))
# end

# function grid_to_feature(grid)
#     vec(Flux.onehotbatch(vec(grid),VALS))
# end


# function generate_x_based_on_episode(init, seq, cart, tf)
#     grid = copy(init)

#     res = Array{Bool, 2}(undef, 14*16+4, length(seq)-1)
#     res[:, 1] .= grid_move_to_feature(grid, seq[1])

#     for i = 2:length(seq)-1
#         #display(grid)
#         move!(grid, seq[i])
#         grid[cart[i]] = tf[i]
#         res[:,i] .= grid_move_to_feature(grid, seq[i])
#     end
#     res
# end

# function sim_one_move_then_end(grid, move)
#     grid_copy = copy(grid)
#     simulate_one!(grid_copy, move)
#     simulate_game!(grid_copy)
#     grid_copy
# end

# function sim_one_move_then_end_n_times(grid, move, n)
#     [sum(sim_one_move_then_end(grid, move)) for i = 1:n]
# end

# function sim_iterate_one_move(grid, vm, n)
#     [sim_one_move_then_end_n_times(grid, move, n) for move in vm]
# end

# # replay the game from beginning to second last move
# function sim_seq!(init, seq, cart, tf)
#     for (s, c, t) in zip(seq, cart, tf)
#         move!(init, s)
#         init[c] = t
#     end
#     init
# end

# function replay_move!(agrid, move, cart, tf)
#     move!(agrid, move)
#     agrid[cart] = tf
#     agrid
# end

# function discounted_policy_rewards(reward_vec, λ)
#     l = length(reward_vec)
#     res = Vector{Float64}(undef, l)
#     res[end] = reward_vec[end] # the last move is always of no value
#     for l1 in l-1:-1:1
#         res[l1] = reward_vec[l1] + res[l1+1]*λ
#     end

#     res
# end


# function discounted_rewards(reward_vec, λ)
#     l = length(reward_vec)
#     res = Vector{Float64}(undef, l)
#     res[l] = 0 # the last move is always of no value
#     for l1 in l-1:-1:1
#         res[l1] = reward_vec[l1] + res[l1+1]*λ
#     end

#     res
# end

# function avg_disc_reward(agrid, n, disc)
#     res = Array{Float64, 1}(undef, n)
#     for i=1:n
#       grid_copy = copy(agrid)
#       (_, _, _, _, _, reward_vec) = simulate_game!(grid_copy)
#       res[i] = discounted_rewards(reward_vec, disc)[1]
#     end
#     StatsBase.mean(res)
# end

# function avg_rewards_next_move(grid, move, n)
#   res = Array{Float64, 1}(undef, n)
#   for i=1:n
#     grid_copy = copy(grid)
#     simulate_one!(grid_copy, move)
#     (_, _, _, _, _, reward_vec) = simulate_game!(grid_copy)
#     res[i] = sum(reward_vec)
#   end
#   StatsBase.mean(res)
# end

# function avg_rewards_next_move(grid, n)
#   vm = valid_moves(grid)
#   res = avg_rewards_next_move.([grid], vm, n)
#   Dict(zip(vm, res))
# end

# function rotatedir(move)
#   if move == :left
#     return (:left, :down, :right, :up, :up, :left, :down, :right)
#   elseif move == :down
#     return (:down, :right, :up, :left, :right, :up, :left, :down)
#   elseif move == :right
#     return (:right, :up, :left, :down, :down, :right, :up, :left)
#   elseif move == :up
#     return (:up, :left, :down, :right, :left, :down, :right, :up)
#   else
#     return (move, move, move, move, move, move, move, move)
#   end
# end

# function rotations(agrid::T, move) where T
#   bgrid::T = transpose(agrid)
#     ((agrid,
#     agrid |> rotl90,
#     agrid |> rot180,
#     agrid |> rotr90,
#     bgrid,
#     bgrid |> rotl90,
#     bgrid |> rot180,
#     bgrid |> rotr90
#     ), rotatedir(move))
#     #((agrid,), (move,))
# end

# struct IdentitySkip
#    inner
#    activation
# end

# (m::IdentitySkip)(x) = m.activation.(m.inner(x) .+ x)
