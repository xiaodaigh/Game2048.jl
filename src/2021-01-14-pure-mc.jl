# I want to try a pure MCTS simulation that doesn't rely on a neural network and
# see how things

using Game2048

using Game2048
using Game2048: bitboard_to_array

function find_best_move(board, n=10000)
    res = zeros(Int, 4)
    for direction in DIRS
        dir_idx = Int(direction) + 1
        new_board = move(board, direction)
        if new_board == board # not a valid move
            res[dir_idx] = -1
            continue
        end

        for _ in 1:n
            # random add one tile
            new_board = add_tile(new_board)

            # simulate from this onward
            res[dir_idx] += sum(2 .^ bitboard_to_array(simulate_bb(new_board)))
        end
    end

    DIRS[argmax(res)]
end


function play_via_monte_carlo(bitboard, n)
     while true
        best_move = find_best_move(bitboard, n)
        # println(best_move)
        new_bitboard = move(bitboard, best_move)
        # display(new_bitboard)

        if new_bitboard != bitboard
            bitboard = add_tile(new_bitboard)
            if bitboard == new_bitboard
                error("wtf")
            end
        else
            # lost
            return bitboard
        end
    end
end


board = initbboard()

@time play_via_monte_carlo(board, 100000)

