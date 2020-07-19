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

const γ = 0.9 # the reward discount rate
const α = 0.001 # learning rate

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

        if greedy
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
        elseif rand() < epsilon
            epsed = true
            i = rand(choices)
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
        # if iseven(i)
            histories, dir_histories, possibles, r, last_board = play_game_with_policy(policy; kwargs...)
        # else
        #     histories, dir_histories, possibles, r, last_board = play_game_with_policy(policy; greedy = true, kwargs...)
        # end
        @assert length(histories) == length(r)

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

    # rewards .= rewards ./ 10

    # mean(rewards[vcat([1], cumsum(l)[1:end-1] .+ 1)] .- mean(rewards))/std(rewards)
    # normalise the rewards
    # the rewards have to be at least rewards
    normalise_scale_rewards!(rewards)
    # println(maximum(rewards))

    @assert length(X) == length(dirs) == length(rewards)
    actual_history = zip(X, dirs, rewards) |> collect

    # for histories with no possible directions
    @assert length(X) == length(p)
    data_impossible = []
    for (h, p1) in zip(X, p)
        for (dir, p1) in zip(DIRS, p1)
            if !p1
                # make that direction impossible!
                push!(data_impossible, (h, dir, -3))
            end
        end
    end

    v1 = vcat(actual_history, data_impossible)

    # now we need to rotate the game
    v2 = eltype(v1)[]
    for (board, dir, reward) in v1
        for (new_board, new_dir) in rotate_mirror(board, dir)
            push!(v2, (new_board, new_dir, reward))
        end
    end
    println("ok")
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

ps = Flux.params(policy)

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
display(showmaxtile(policy; n=100))

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

function ok()
    batch=1
    while true
        println("batch $batch")
        @time Xy = many_games(policy; n=1000, epsilon=0.1, greedy = false);
        Xy = sample(Xy, length(Xy), replace=false)
        for (board, dir, reward) in Xy
            policy(board)
            update_param!(ps, board, dir, reward)
        end
        play_game_with_policy(policy, verbose=true, min_remarkable=0.3)
        display(showmaxtile(policy; greedy=true))
        display(showmaxtile(policy; greedy=false))

        batch += 1
    end
end

ok()
