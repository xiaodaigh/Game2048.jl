# in this attempt, I shall play a set of games with the policy and move the policy using
# the data
using Game2048
using Flux
using Flux: logitcrossentropy, crossentropy
using StatsBase: wsample, sample, countmap
using Statistics: mean, std
using Base.Threads: @threads

# based on testing gpu is slower than cpu, so forget that idea for now
# see benchmarks/gpu_slower_than_cpu.jl
# using CUDA

function loss(x, y)
    crossentropy(policy(x), y)
end

function next_game()
    i = 1
    return function()
        display(h[i])
        display(policy(h[i]))
        i+=1
    end
end

ng = next_game()

function play_game_with_policy(policy; verbose=false, goal=8, epsilon=0, greedy=false)
    board = initboard()

    histories = Array{Int8, 2}[]
    dir_histories = Dirs[]
    possibles = Vector{Bool}[]
    max_prob = 0
    remarkable=false
    while true
        res = move.(Ref(board), DIRS)
        possible = [p for (_, (_, p)) in res]
        #possible::Vector{Bool} = [p for (_, (_, p)) in res]

        if all(!, possible)
            return histories, dir_histories, possibles, board
        end

        choices = (1:4)[possible]

        if greedy
            epsed = false
            prob = policy(board)[possible]
            remarkable = maximum(prob) > 0.9
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
        elseif rand() < epsilon
            epsed = true
            i = rand(choices)
        else
            epsed = false
            prob = policy(board)[possible]
            remarkable = maximum(prob) > 0.9
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
            println("****************************begin: one move")
            display(board)
            println(dir)
            println(DIRS[choices])
            if epsed
                "epsilon'ed"
            else
                println(prob)
            end
        end
        push!(histories, board)
        push!(dir_histories, dir)
        push!(possibles, possible)
        board = res[i][1]

        if verbose && remarkable
            display(board)
            println("****************************end: one move")
        end
        remarkable = false
        gen_new_tile!(board)
    end
end

function action2vec(dir, val = 1.0)
    a = zeros(Float32, 4)
    if val > 0
        a .= 0.04
        a[Int(dir)+1] = 0.88
    else
        a .= 0.33
        a[Int(dir)+1] = 0.01
    end
    a
end

function normalise_scale_rewards!(rewards, min_rewards)
    mean_lvl = max(min_rewards, mean(rewards))
    rewards .= (rewards .- mean_lvl) ./ std(rewards)
    # min3, max3 = extrema(rewards)
    # for (i, r) in enumerate(rewards)
    #     ratio = r > 0 ? 3/max3 : -3/min3
    #     @inbounds rewards[i] = r * ratio
    # end
    rewards
end

function many_games(policy; n=20, min_reward = 300, kwargs...)
    @assert n > 3
    rewards = zeros(Float32, n)
    X = Vector{Array{Int8, 4}}()
    dirs = []
    l = Int[]
    p = Vector{Bool}[]
    for i in 1:n
        # global X, dirs, l
        if iseven(i)
            histories, dir_histories, possibles, last_board = play_game_with_policy(policy; kwargs...)
        else
            histories, dir_histories, possibles, last_board = play_game_with_policy(policy; greedy = true, kwargs...)
        end
        X = vcat(X, histories)
        dirs = vcat(dirs, dir_histories)
        push!(l, length(dir_histories))
        p = vcat(p, possibles)
        rewards[i] = sum(2 .^ last_board)
    end

    # for histories with no possible directions
    @assert length(X) == length(p)
    data_impossible = []
    for (h, p1) in zip(X, p)
        for (dir, p1) in zip(DIRS, p1)
            if !p1
                push!(data_impossible, (h, action2vec(dir, - 3)))
            end
        end
    end

    # the rewards have to be at least rewards
    normalise_scale_rewards!(rewards, min_reward)
    println(maximum(rewards))

    rewards_vec = Float32[]

    for (r, l1) in zip(rewards,l)
        rewards_vec = vcat(rewards_vec, [r for j in 1:l1])
    end

    actual_history = [(X1, action2vec(d, r)) for (X1, d, r) in zip(X, dirs, rewards_vec)]

    v1 = vcat(actual_history, data_impossible)
    v1
end

function showmaxtile(policy; n=100, kwargs...)
    res = Vector{Int}(undef, n)
    @threads for i in 1:n
        res[i] = play_game_with_policy(policy; verbose=false, kwargs...)[end] |> maximum
    end
    countmap(res) |> sort
end

struct IdentitySkip
   inner
   activation
end

(m::IdentitySkip)(x) = m.activation.(m.inner(x) .+ x)

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

p = Flux.params(policy)
opt=ADAM()

# display(showmaxtile(policy; n=10000))
# random
# OrderedCollections.OrderedDict{Int64,Int64} with 6 entries:
#   4 => 31
#   5 => 666
#   6 => 3651
#   7 => 4817
#   8 => 832
#   9 => 3
display(showmaxtile(policy; n=100))

function ok()
    batch=1
    min_reward = 300
    while true
        println("batch $batch")
        @time Xy = many_games(policy; min_reward=min_reward, n=100);
        Xy = sample(Xy, length(Xy), replace=false)
        @time Flux.train!(loss, p, Xy, opt)
        play_game_with_policy(policy, verbose=true)
        display(showmaxtile(policy; greedy=true))
        display(showmaxtile(policy; greedy=false))

        batch += 1
        min_reward += 1
    end
end

ok()
