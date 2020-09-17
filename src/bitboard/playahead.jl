export play_ahead

using Base.Threads: @threads
using DataStructures

function play_ahead(board, dict, queue)
    start_time = time()
    new_time = start_time

    enqueue!(queue, board)
    dict[bitboard_to_array(board)] = true

    terminal = Bitboard[]

    while new_time - start_time < 1 # only run this for one second
        if length(queue) > 0
            board = dequeue!(queue)
        else
            return terminal
        end
        can_move = false
        for j in 1:4
            dir = DIRS[j]
            next_board = move(board, dir)
            if next_board != board
                can_move = true
                cnt_empty = count0(next_board)
                for i in 1:cnt_empty
                    tmp_board  = add_tile(next_board, i, 1)
                    btatb = bitboard_to_array(tmp_board)
                    if !any(board->haskey(dict, board), rotate_mirror(btatb))
                        enqueue!(queue, tmp_board)
                        dict[btatb] = true
                    end
                    # enqueue!(queue, tmp_board)

                    tmp_board  = add_tile(next_board, i, 2)
                    btatb = bitboard_to_array(tmp_board)
                    if !any(board->haskey(dict, board), rotate_mirror(btatb))
                        enqueue!(queue, tmp_board)
                        dict[btatb] = true
                    end
                    # enqueue!(queue, tmp_board)
                end
            end
        end
        if !can_move
            push!(terminal, board)
        end
        new_time = time()
    end
    return terminal
end