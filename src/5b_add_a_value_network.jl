# in this attempt, I shall play a set of games with the policy and move the policy using
# the data
# Zj: notes, this method is a complete disaster and the average scores
# just get worse and worse
using Game2048
using Flux
using Flux: logitcrossentropy, crossentropy
using StatsBase: wsample, sample, countmap, corspearman
using Statistics: mean, std
using Base.Threads: @threads

# based on testing gpu is slower than cpu, so forget that idea for now
# see benchmarks/gpu_slower_than_cpu.jl
# using CUDA

const γ = 0.995 # the reward discount rate
const α = 0.00001 # learning rate

function play_game_with_policy(policy; verbose=false, epsilon=0, greedy=false, min_remarkable=0.3)
    board = initboard()

    histories = Array{Int8, 2}[]
    dir_histories = Dirs[]
    possibles = Vector{Bool}[]
    max_prob = 0
    remarkable=false
    rewards = Int[]
    while true
        res = move.(Ref(board), DIRS)
        possible = [p for (_, (_, p)) in res]
        #possible::Vector{Bool} = [p for (_, (_, p)) in res]

        if all(!, possible)
            return histories, dir_histories, possibles, rewards, board
        end

        choices = (1:4)[possible]

        if rand() < epsilon
            epsed = true
            i = rand(choices)
        elseif greedy
            epsed = false
            prob = policy(board)[possible]
            remarkable = maximum(prob) > min_remarkable
            if maximum(prob) > max_prob
                max_prob = maximum(prob)
                # remarkable = true
            end
            if any(isnan, prob)
                println(prob)
                error("wtf")
            end
            # sample a direction from policy
            _, ii = findmax(prob)
            i = choices[ii]
        else
            epsed = false
            prob = policy(board)[possible]
            remarkable = maximum(prob) > min_remarkable
            if maximum(prob) > max_prob
                max_prob = maximum(prob)
                # remarkable = true
            end
            if any(isnan, prob)
                println(prob)
                error("wtf")
            end
            # sample a direction from policy
            i = wsample(choices, prob)
        end

        dir = DIRS[i]
        if verbose && remarkable
            println("")
            println("")
            println("****************************begin: one move")
            display(board)
            println(dir)
            println(DIRS[choices])
            println(valuenn(board))
            if epsed
                "epsilon'ed"
            else
                println(prob)
            end
        end
        push!(histories, board)
        push!(dir_histories, dir)
        push!(possibles, possible)
        push!(rewards, res[i][2][1])

        board = res[i][1]

        if verbose && remarkable
            display(board)
            println("--------------------------------end: one move")
            println("")
            println("")
        end
        remarkable = false
        gen_new_tile!(board)
    end
end

function normalise_scale_rewards!(rewards)
    mean_lvl = mean(rewards)
    rewards .= (rewards .- mean_lvl) ./ std(rewards)
    rewards
end

function many_games(policy; n=20, kwargs...)
    @assert n > 3
    rewards = Float32[]
    X = Vector{Array{Int8, 4}}()
    dirs = []
    l = Int[]
    p = Vector{Bool}[]
    for i in 1:n
        # global X, dirs, l, p, rewards
        histories, dir_histories, possibles, r, last_board = play_game_with_policy(policy; kwargs...)
        X = vcat(X, histories)
        dirs = vcat(dirs, dir_histories)
        push!(l, length(dir_histories))
        p = vcat(p, possibles)

        # compute the discounted rewards
        tmp_r = Vector{Float32}(undef, length(r))
        tmp_r[end] = log(1+r[end])
        for i in length(r)-1:-1:1
            tmp_r[i] = log(1+r[i]) + tmp_r[i+1]*γ
        end
        rewards = vcat(rewards, tmp_r)
    end

    @assert length(X) == length(dirs) == length(rewards)
    actual_history = zip(X, dirs, rewards) |> collect

    # for histories with no possible directions
    # @assert length(X) == length(p)
    # data_impossible = []
    # for (h, p1) in zip(X, p)
    #     for (dir, p1) in zip(DIRS, p1)
    #         if !p1
    #             # make that direction impossible!
    #             push!(data_impossible, (h, dir, -3))
    #         end
    #     end
    # end

    # v1 = vcat(actual_history, data_impossible)

    # now we need to rotate the game
    v2 = eltype(actual_history)[]
    for (board, dir, reward) in actual_history
        for (new_board, new_dir) in rotate_mirror(board, dir)
            push!(v2, (new_board, new_dir, reward))
        end
    end
    v2
end

function showmaxtile(policy; n=100, kwargs...)
    res = Vector{Int}(undef, n)
    @threads for i in 1:n
        res[i] = play_game_with_policy(policy; verbose=false, kwargs...)[end] |> maximum
    end
    countmap(res) |> sort
end


function update_param!(ps, board, dir, reward)
    grad = gradient(()-> reward*log(1+policy(board)[Int(dir)+1]), ps)
    for p1 in ps
        Flux.update!(p1, -α*grad[p1])
    end
end

policy = Chain(
    board -> Float32.(board),
    board -> board ./ maximum(board),
    board -> reshape(board, 16),
    Dense(16, 20, relu),
    IdentitySkip(Dense(20, 20, relu), identity),
    IdentitySkip(Dense(20, 20, relu), identity),
    Dense(20, 4),
    softmax
)

valuenn = Chain(
    board -> Float32.(board),
    board -> board ./ maximum(board),
    board -> reshape(board, 16),
    Dense(16, 20, relu),
    IdentitySkip(Dense(20, 20, relu), identity),
    IdentitySkip(Dense(20, 20, relu), identity),
    Dense(20, 1)
)

function loss_value(board, discounted_reward)
    (valuenn(board)[1] - discounted_reward).^2
end

ps = Flux.params(policy)
pv = Flux.params(valuenn)
opt_pv = ADAM()

if false
    # show change in policy
    board = initboard()
    policy(board)
    update_param!(ps, board, left, 3)
    policy(board)
    update_param!(ps, board, left, -3)
    policy(board)


    board = initboard()
    board
    function doit()
        display(board)
        pb=policy(board)
        dir = wsample(DIRS, pb)
        move!(board, dir);
        gen_new_tile!(board)
        println(dir)
        println(pb)
        println(valuenn(board))
        display(board)
    end

    doit()
end

# display(showmaxtile(policy; n=10000))
# random
# OrderedCollections.OrderedDict{Int64,Int64} with 6 entries:
#   4 => 31
#   5 => 666
#   6 => 3651
#   7 => 4817
#   8 => 832
#   9 => 3
# display(showmaxtile(policy; n=100))

if false
    i= 1

    while !any(isnan, policy(board))
        global i
        board, dir, reward = Xy[i]
        println(policy(board))
        # display(board)
        dir
        update_param!(ps, board, dir, reward)
        println(policy(board))
        i+=1
    end
end

using Plots

function ok(;min_remarkable=0.3, nper=10, epsilon=1, epsilon_decay = 0.995, epsilon_min = 0.1)
    global true_rewards_over_time, valuenn_rewards_overtime
    batch=1

    while true
        println("batch $batch epsilon $epsilon")
        @time Xy = many_games(policy; n=nper, epsilon=epsilon, greedy = false);
        @assert length(Xy) > 0
        Xy = sample(Xy, length(Xy), replace=false)

        # update value network
        data_for_value = [(board, reward) for (board, _, reward) in Xy]
        Flux.train!(loss_value, pv, data_for_value, opt_pv)

        reward_for_policy = [valuenn(board)[1] for (board, _) in data_for_value]
        true_rewards = map(x->x[3], Xy)


        println(corspearman(true_rewards, reward_for_policy))
        # println(sum((reward_for_policy .- true_rewards).^2))
        # println(maximum(abs.(reward_for_policy.-true_rewards)))
        println(maximum(true_rewards))
        println(maximum(reward_for_policy))
        push!(true_rewards_over_time, mean(true_rewards))
        push!(valuenn_rewards_overtime, mean(reward_for_policy))
        println(true_rewards_over_time)
        println(valuenn_rewards_overtime)


        # normalise_scale_rewards!(reward_for_policy)

        reward_for_policy .= (reward_for_policy .- mean(reward_for_policy))./std(reward_for_policy)

        for ((board, dir, _), r) in zip(Xy, reward_for_policy)
            # update policy network
            update_param!(ps, board, dir, r)
        end


        play_game_with_policy(policy, verbose=true, min_remarkable=min_remarkable)
        display(showmaxtile(policy; greedy=true))
        display(showmaxtile(policy; greedy=false))

        batch += 1
        epsilon = max(epsilon_min, epsilon*epsilon_decay)
    end
end

true_rewards_over_time = Float64[]
valuenn_rewards_overtime = Float64[]
ok(;min_remarkable = 0.80, nper=100, epsilon=1, epsilon_decay = 0.999, epsilon_min = 0.1)
# plot(true_rewards_over_time)
# plot!(valuenn_rewards_overtime)

valuenn(initboard())