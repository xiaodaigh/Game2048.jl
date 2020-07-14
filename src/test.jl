# Doing epsilon greedy
# https://youtu.be/PnHCvfgC_ZA?t=3013

using Flux

critic_model1 = Chain(
    boardmove -> (reshape(boardmove[1], 4, 4, 1, 1), boardmove[2]),
    boardmove -> (Conv((2,2), 1=>64, relu)(boardmove[1]), boardmove[2]),
    boardmove -> (Conv((2,2), 64=>128, relu)(boardmove[1]), boardmove[2]),
    boardmove -> vcat(reshape(boardmove[1], 2*2*128), boardmove[2]),
    Dense(2*2*128+4, 256, relu),
    Dense(256, 1, exp)
)

loss_qa(boardmove, expected_value) = begin
    oldSA = critic_model1(boardmove)
    sum((oldSA .- expected_value).^2)
end

board = zeros(Float32, 4, 4)
opt = ADAM()
X = (board, rand(Float32, 4))
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