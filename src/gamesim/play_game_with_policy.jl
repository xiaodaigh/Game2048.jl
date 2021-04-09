# export play_game_with_policy

# using Flux:softmax
# using StatsBase: wsample

# const EPSILON = 0.1

# function play_game_with_policy(policy; verbose=false, goal=8, epsilon=EPSILON)
#     board = initboard()

#     histories = Array{Int8, 2}[]
#     dir_histories = Dirs[]
#     while true
#         res = move.(Ref(board), DIRS)
#         # possible = [p for (_, (_, p)) in res]
#         possible::Vector{Bool} = [p for (_, (_, p)) in res]


#         if all(!, possible)
#             return histories, dir_histories, board
#         end

#         choices = (1:4)[possible]

#         if rand() < epsilon
#             epsed = true
#             i = rand(choices)
#         else
#             epsed = false
#             tmp = policy(board)
#             prob = reshape(tmp, 4)
#             if any(isnan, prob)
#                 error("wtf")
#             end
#             # sample a direction from policy
#             i = wsample(choices, prob)
#         end

#         dir = DIRS[i]
#         if verbose
#             println("****************************begin: one move")
#             display(board)
#             println(dir)
#             println(DIRS[choices])
#             if epsed
#                 "epsilon'ed"
#             else
#                 println(prob)
#             end
#         end
#         push!(histories, board)
#         push!(dir_histories, dir)
#         board = res[i][1]

#         if verbose
#             display(board)
#             println("****************************end: one move")
#         end
#         gen_new_tile!(board)
#     end
# end