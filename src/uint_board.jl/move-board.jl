using Base.Threads: @threads



function move(board, dir)
    copy_board = deepcopy(board)
    copy_board, move!(copy_board, dir)
end

"""make_one_move on game board"""
function move!(board, dir::Dirs)::Tuple{Int, Bool}
    move!(board, Val(dir))
end

function move!(board, ::Val{left})
    tot_pts = 0
    any_updated = false
    for i in 1:4
        _, pts, updated = move_up!(@view board[i, :])
        tot_pts += pts
        any_updated |= updated
    end
    tot_pts, any_updated
end

function move!(board, ::Val{right})
    tot_pts = 0
    any_updated = false
    for i in 1:4
        _, pts, updated = move_up!(@view board[i, 4:-1:1])
        tot_pts += pts
        any_updated |= updated
    end
    tot_pts, any_updated
end

function move!(board, ::Val{up})
    tot_pts = 0
    any_updated = false
    for i in 1:4
        _, pts, updated = move_up!(@view board[:, i])
        tot_pts += pts
        any_updated |= updated
    end
    tot_pts, any_updated
end

function move!(board, ::Val{down})
    tot_pts = 0
    any_updated = false
    for i in 1:4
        _, pts, updated = move_up!(@view board[4:-1:1, i])
        tot_pts += pts
        any_updated |= updated
    end
    tot_pts, any_updated
end