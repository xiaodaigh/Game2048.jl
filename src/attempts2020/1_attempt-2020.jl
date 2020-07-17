using Game2048, Flux
using BenchmarkTools
using Flux: relu, softmax
using StatsBase, Statistics

function mirrors_rotations(board)
    tboard = transpose(board) |> collect

    return board,  rotl90(board),  rot180(board),  rotr90(board),
           tboard, rotl90(tboard), rot180(tboard), rotr90(tboard)
end

# simulate the game current that

# do a policy gradient approach
# for each step update the policy
model = Chain(
    normalised_board -> reshape(normalised_board, 4, 4, 1, 1),
    Conv((3,3), 1=>256, relu),
    Conv((3,3), 256=>128, relu),
    x->reshape(x, 128),
    Dense(128, 4),
    softmax
)

loss(board, means_scores) = crossentropy(model(board), softmax(means_scores))

params = Flux.params(model);

opt = ADAM()

function simulate_game_for_mean_score(board, dir)::Tuple{Float32, Bool}
    pts, possible = move!(deepcopy(board), dir)

    if possible
        return mean(simulate_games(1000, board, pts)), possible
    else
        return 0.0, possible
    end
end



function return_best_dir(board)
    ms_pos = simulate_game_for_mean_score.(Ref(board), DIRS)
    mean_scores = [ms for (ms, _) in ms_pos]
    possible = [p for (_, p) in ms_pos]
    (mean_scores .- mean(mean_scores))./std(mean_scores), possible
end


function play_game_with_policy_update!(loss, params, model, opt)
    board = initboard()
    most_sure_move_pct = 0.25

    while true
        mean_scores, possible = return_best_dir(board)

        if all(!, possible)
            return board
        end

        board_float32 = board ./ maximum(board)
        # training_data = [(b, mean_scores) for b in mirrors_rotations(board_float32)]

        training_data = [(board_float32, mean_scores)]

        Flux.train!(loss, params, training_data, opt)
        prob = model(board_float32)
        if maximum(prob) > most_sure_move_pct
            max_prob, i = findmax(prob)
            most_sure_move_pct = max_prob
            println("it is very sure - '$(DIRS[i])' $most_sure_move_pct")
            display(board)
        end
        # sample a direction from policy
        dir = wsample(DIRS[possible], prob[possible])
        # println(dir)
        move!(board, dir)
        gen_new_tile!(board)
        # display(board)
    end
end

function play_game_with_policy(model)
    board = initboard()

    while true
        possible = [p for (_, p) in move.(Ref(board), DIRS)]
        if all(!, possible)
            return board
        end

        board_float32 = board ./ maximum(board)
        prob = model(board_float32)
        # println(maximum(prob))

        # sample a direction from policy
        dir = wsample(DIRS[possible], prob[possible])
        # println(dir)
        move!(board, dir)
        gen_new_tile!(board)
        # display(board)
    end
end


function train_many_times!(res, times, loss, params, model, opt)
    for i in 1:times
        finalised_board = play_game_with_policy_update!(loss, params, model, opt)
        println("******************************self play report trends:***********************")
        display(finalised_board)
        play_max = [maximum(play_game_with_policy(model)) for i in 1:100]
        cm = countmap(play_max)
        display(sort(collect(cm), by = x->x[1]))
        push!(res, mean(play_max))
        println("$(mean(res)) $(res[end-7:end])")
        println("*****************************************************")
    end
end

# res = [6.0 for i in 1:8]
@time train_many_times!(res, 1200, loss, params, model, opt)

