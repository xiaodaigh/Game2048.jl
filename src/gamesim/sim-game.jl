export initboard, gen_new_tile!, sim_one_move!, simulate_game, simulate_games, DIRS

using Base.Threads

const DIRS = (left, right, up, down)

"""intiialise the game board"""
function initboard(random2=true)
    board = zeros(Int8, 4, 4)
    if random2
        gen_new_tile!(board)
        gen_new_tile!(board)
    end
    board
end

const PROB4 = 0.1 # probability of seeing a 4

function gen_new_tile!(board, pos = rand(findall(==(0), board)))
    board[pos] = rand() > PROB4 ? 1 : 2
    board
end

# it moves but doesn't generate new tile
function sim_one_move!(board)
    dirs = collect(DIRS)
    size = 4
    pts = 0

    updated = false

    while !updated && size >= 1
        pos = rand(1:size)
        pts, updated = move!(board, dirs[pos])
        dirs[pos] = dirs[size]
        size -= 1
    end
    pts, updated
end

function simulate_game(board = initboard(), score::Int = 0, delta=1)
    hehe = []
    pts, update_possible =  sim_one_move!(board)
    rounds = 0

    while update_possible
        score += pts*delta^rounds
        gen_new_tile!(board)
        pts, update_possible =  sim_one_move!(board)

        rounds += 1
    end

    board, score, rounds
end

function simulate_games(n, board = initboard(), score::Int = 0)
    res = Vector{Int}(undef, n)
    @threads for i in 1:n
        _, pts = simulate_game(deepcopy(board), score)
        res[i] = pts
    end
    res
end
