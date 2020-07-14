# Doing epsilon greedy
# https://youtu.be/PnHCvfgC_ZA?t=3013

using Game2048
using Flux

const EPSILON = 0.5
const LAMBDA = 0.9 # the discount fcator

function mirrors_rotations(board)
    tboard = transpose(board) |> collect

    return board,  rotl90(board),  rot180(board),  rotr90(board),
           tboard, rotl90(tboard), rot180(tboard), rotr90(tboard)
end

actor_model = Chain(
    board -> Float32.(board ./ maximum(board)),
    normalised_board -> reshape(normalised_board, 4, 4, 1, 1),
    Conv((2,2), 1=>64, relu),
    Conv((2,2), 64=>128, relu),
    x->reshape(x, 2*2*128),
    Dense(128*2*2, 4),
    softmax
)

critic_model1 = Chain(
    # boardmove -> (boardmove[1] ./ maximum(boardmove[1]), boardmove[2]),
    boardmove -> (reshape(boardmove[1], 4, 4, 1, 1), boardmove[2]),
    boardmove -> (Conv((2,2), 1=>64, relu)(boardmove[1]), boardmove[2]),
    boardmove -> (Conv((2,2), 64=>128, relu)(boardmove[1]), boardmove[2]),
    boardmove -> vcat(reshape(boardmove[1], 2*2*128), boardmove[2]),
    Dense(2*2*128+4, 256, relu),
    # Dense(256, 1, exp)
)

critic_model2 = Chain(
    Dense(2*2*128+4, 256, relu),
    Dense(256, 1, exp)
)

function action2vec(dir)
    a = zeros(Float32, 4)
    a[Int(dir)+1] = 1
    a
end

board = initboard()

p = Flux.params(critic_model1)
normalised_board(board) = Float32.(board ./ maximum(board))
critic_model1([board |> normalised_board, action2vec(left)])

loss_qa(boardmove, expected_value) = begin
    #sum(sum.(boardmove))
    oldSA = critic_model1(boardmove)
    sum(oldSA)
    #sum(oldSA)
    #sum((oldSA .- expected_value).^2)
    # sum((oldSA .- (reward .+ LAMBDA.*newSA)).^2)

end

opt = ADAM()
normalised_board(board) = Float32.(board ./ maximum(board))
X = [board |> normalised_board, action2vec(left)]
Y = Float32[10.0]
loss_qa(X, Y)

Flux.train!(loss_qa, p, [(X, Y)], opt)

# S,A
# R = Reward
# S'
# A'
# = SARSA

res = move.(Ref(board), DIRS)
possible = map(r->r[2][2], res)
prob_dir = actor_model(board)[possible]
_, greedy_pos = findmax(prob_dir)
reward = map(r->r[2][1], res)[possible][greedy_pos]
dir = rand() < EPSILON ? rand(DIRS[possible]) : DIRS[possible][prob_dir]


features = critic_model1([board, action2vec(dir)])
SA = critic_model2(vcat(features, action2vec(dir)))

#  up to here I have the SAR
new_state = res[possible][greedy_pos][1]
gen_new_tile!(new_state)
res = move.(Ref(new_state), DIRS)
possible = map(r->r[2][2], res)
prob_dir = actor_model(new_state)[possible]
_, greedy_pos = findmax(prob_dir)
reward = map(r->r[2][1], res)[possible][greedy_pos]
dir = rand() < EPSILON ? rand(DIRS[possible]) : DIRS[possible][greedy_pos]
features = critic_model1(new_state)
newSA = critic_model2(vcat(features, action2vec(dir)))

action = dir
loss_qa(boardmove, expected_value) = begin
    oldSA = critic_model1(boardmove)
    sum((oldSA .- estimate_reward).^2)
    # sum((oldSA .- (reward .+ LAMBDA.*newSA)).^2)
end

estimate_reward = reward + LAMBDA*newSA[1]

p = Flux.params(critic_model1)
opt = ADAM()
loss_qa(([board, action2vec(dir)], estimate_reward)...)
Flux.train!(loss_qa, p, [([board, action2vec(dir)], estimate_reward)], opt)



@time actor_model(board)
@time critic_model.(map(res->res[1], res))

using Flux:crossentropy
crossentropy([0.97, 0.01, 0.01, 0.01],[ 1, 0, 0, 0])