# Doing epsilon greedy
# https://youtu.be/PnHCvfgC_ZA?t=3013

using Game2048
using Flux, Statistics, StatsBase
using Flux: crossentropy
using BSON: @save, @load
using CUDA:cu
using CUDA
CUDA.allowscalar(false)

const EPSILON = 0.1
const LAMBDA = 0.95 # the discount fcator

function mirrors_rotations(board)
    tboard = transpose(board) |> collect

    return board,  rotl90(board),  rot180(board),  rotr90(board),
           tboard, rotl90(tboard), rot180(tboard), rotr90(tboard)
end

actor_model = Chain(
    normalised_board -> reshape(normalised_board, 4, 4, 1, 1),
    Conv((2,2), 1=>256, relu),
    Conv((2,2), 256=>512, relu),
    Conv((2,2), 512=>1024, relu),
    x->reshape(x, 1024),
    Dense(1024, 4),
    softmax
) |> gpu

function loss_actor(board_float32, prob)
    crossentropy(actor_model(board_float32), prob)
end

critic_model1 = Chain(
    board -> reshape(board, 4, 4, 1, 1),
    Conv((2,2), 1=>256, relu),
    Conv((2,2), 256=>512, relu),
    Conv((2,2), 512=>1024, relu),
    x->reshape(x, 1024)
) |> gpu

critic_model2 = Chain(
    Dense(1024+4, 512, relu),
    Dense(512, 256, relu),
    Dense(256, 1, exp)
) |> gpu

function critic_score(board, dir)
    v1 = critic_model1(cu(Float32.(board)))
    v2 = cu(action2vec(dir))
    res = critic_model2(vcat(v1, v2)) |> collect
    res[1]
end

function action2vec(dir)
    a = zeros(Float32, 4)
    a[Int(dir)+1] = 1
    a
end

function loss_qa((board, v2), expected_value)
    v1 = critic_model1(board)
    v3 = critic_model2(vcat(v1, v2))
    sum((v3 .- expected_value).^2)
end

# figure out the possible actions
# and sample a move from the actor
function choose_action(board)
    res = move.(Ref(board), DIRS)
    possible = map(r->r[2][2], res)

    if !any(possible)
        return false, left, 0, board
    end

    if rand() <= EPSILON
        i = wsample(1:4, possible)
    else
        prob_dir = collect(actor_model(cu(Float32.(board))))
        if all(isnan, prob_dir)
            error("wtf")
        end
        prob_dir .= prob_dir .* possible
        i = wsample(1:4, prob_dir)
    end

    reward = res[i][2][1]
    dir = DIRS[i]
    new_board = res[i][1]

    true, dir, reward, new_board
end

function train_one_episode() #p, opt)
    # keep track of actions taken
    historiesX = []
    board = initboard()

    cstmp = critic_score.(Ref(board), DIRS)
    println("*****************my abilities now***********************")
    println(cstmp |> mean)
    display(cstmp)
    display(softmax(cstmp./100))
    println("****************************************")

    # choose an action
    possible, dir, reward, new_board = choose_action(board)

    # save the history
    push!(historiesX, (cu(Float32.(board)), cu(action2vec(dir))))

    max_reward = 2^8
    tot_reward = 0
    rewards = Int[]
    max_critic_scores = 0
    while possible
        # move according to choosen action
        board = new_board
        gen_new_tile!(board)

        # update the critic network with latest info
        possible, dir, reward, new_board = choose_action(board)

        tot_reward += reward
        push!(rewards, reward)

        if possible
            cs = critic_score(board, dir)
            y = zeros(Float32, length(historiesX))
            yscore = cs*LAMBDA
            for i in length(y):-1:1
                yscore += rewards[i]
                y[i] = yscore
                yscore *= LAMBDA
            end

            if reward >= max_reward
                max_reward = reward
                display(board)
                println(dir)
                println(y)
            end

            training_data = [(X, cu([y1])) for (X, y1) in zip(historiesX, y)]

            # update the critic network
            Flux.train!(loss_qa, p, training_data, opt)

            # use the updated critic network to update actor network
            critic_scores = critic_score.(Ref(board), DIRS)
            critic_scores .= softmax(critic_scores ./ 100)
            if maximum(critic_scores) > max_critic_scores
                _, pos = findmax(critic_scores)
                max_critic_scores = maximum(critic_scores)
                println("*************best score******************")
                println("$(DIRS[pos]) $max_critic_scores")
                display(board)
            end
            nboard = Float32.(board)
            nboard = cu(nboard ./ maximum(nboard))

            Flux.train!(loss_actor, pam, [(nboard, cu(critic_scores))], opt_pam)

            # display(board)
            # println(dir)
            # println(cs)
            # to save on computional power just reuse the previous chosen action
            push!(historiesX, (cu(Float32.(board)), action2vec(dir) |> cu))
        else
            return board, tot_reward, rewards
        end


    end
end

if 1 == 2
    p = Flux.params(critic_model1, critic_model2)
    opt = ADAM()

    pam = Flux.params(actor_model)
    opt_pam = ADAM()
elseif 2 == 3
    using Zygote
    @load "actor"
    @load "critic1"
    @load "critic2"
    @load "actor_p"
    @load "critic1_p"
    @load "critic2_p"
    @load "opt"
    @load "opt_pam"
    Flux.loadparams!(actor_model, pam)
    Flux.loadparams!(critic_model1, c1)
    Flux.loadparams!(critic_model2, c2)
end

@time res = train_one_episode()

for i in 1:600
    @time println(train_one_episode())
    if i % 10 == 0
        @save "actor" actor_model
        @save "critic1" critic_model1
        @save "critic2" critic_model2

        @save "opt" opt
        @save "opt_pam" opt_pam

        @save "actor_p" pam
        c1 = Flux.params(critic_model1)
        @save "critic1_p" c1

        c2 = Flux.params(critic_model2)
        @save "critic2_p" c2
    end
end
