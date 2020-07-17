# Doing epsilon greedy
# https://youtu.be/PnHCvfgC_ZA?t=3013

using Game2048
using Flux, Statistics, StatsBase
using Flux: crossentropy
# using CUDA:cu
# using CUDA
# CUDA.allowscalar(false)

const EPSILON = 0.5
const LAMBDA = 0.95 # the discount fcator

function mirrors_rotations(board)
    tboard = transpose(board) |> collect

    return board,  rotl90(board),  rot180(board),  rotr90(board),
           tboard, rotl90(tboard), rot180(tboard), rotr90(tboard)
end

actor_model = Chain(
    normalised_board -> reshape(normalised_board, 4, 4, 1, 1),
    Conv((3,3), 1=>512, relu),
    Conv((3,3), 512=>256, relu),
    x->reshape(x, 256),
    Dense(256, 4),
    softmax
)

function loss_actor(board_float32, prob)
    crossentropy(actor_model(board_float32), prob)
end

critic_model1 = Chain(
    board -> reshape(board, 4, 4, 1, 1),
    Conv((2,2), 1=>256, relu),
    Conv((2,2), 256=>512, relu),
    Conv((2,2), 512=>1024, relu),
    x->reshape(x, 1024)
)

critic_model2 = Chain(
    Dense(1024+4, 512, relu),
    Dense(512, 256, relu),
    Dense(256, 1, exp)
)

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

    prob_dir = collect(actor_model(cu(Float32.(board))))[possible]
    if all(isnan, prob_dir)
        error("wtf")
    end
    i = wsample(1:4, prob_dir)

    reward = res[possible][i][2][1]
    dir = DIRS[i]
    new_board = res[possible][i][1]

    true, dir, reward, new_board
end

function train_one_episode() #p, opt)
    board = initboard()
    # choose an action
    @time possible, dir, reward, new_board = choose_action(board)

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

        if !possible
            return board, tot_reward, rewards
        end

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
        nboard = Float32.(board)
        nboard = cu(nboard ./ maximum(nboard))

        Flux.train!(loss_actor, pam, [(nboard, cu(critic_scores))], opt_pam)


        # display(board)
        # println(dir)
        # println(cs)
        # to save on computional power just reuse the previous chosen action
        push!(historiesX, (cu(Float32.(board)), action2vec(dir) |> cu))
    end
end

p = Flux.params(critic_model1, critic_model2)
opt = ADAM()

pam = Flux.params(actor_model)
opt_pam = ADAM()

@time res = train_one_episode()

for i in 1:600
    @time println(train_one_episode())
end
