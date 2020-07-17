export LEFT, RIGHT, move

# A gameboard is stored on a UInt (64bit)
# where each cell is
const MASK=UInt16(2^16-1)
const CELLMASK=UInt16(2^4-1)

const LEFT = make_row_lookup()
const RIGHT = make_row_lookup()

"""
    board2cols(board::UInt64)::Vector{Vector{UInt16}}


Return the columns from a board
"""
function board2cols(board::UInt64)::Vector{UInt16}
    # initialise the columns
    cols = zeros(UInt16, 4)

    # take one row at a time
    for row_shift in 48:-16:0
        row = board >> row_shift

        # populate the right cell for each column
        for i in 4:-1:1
            cols[i] <<= 4 # doing this here effectively means each col only gets shifted 3 times
            cols[i] |= row & CELLMASK
            row >>= 4
        end
    end
    cols
end

"""
    move(board::UInt64, dir::Dirs)::UInt64
    move(board::UInt64, LOOKUP::Vector{UInt16}::UInt64

Bitboard game
"""
function move(board::UInt64, LOOKUP::Vector{UInt16})
    idx = board >> 48
    new_board = idx

    for i in 32:-16:0
        new_board << 16
        idx = (board >> i) & MASK
        new_board |= LOOKUP[idx+1]
    end
    new_board
end

function move_updown(board::UInt64, LOOKUP::Vector{UInt16})
    cols = board2cols(board)
    cols_moved = [LOOKUP[c+1] for c in cols]

    new_board = zero(UInt64)

    # construct the new board by putting the columns in to rows
    for (colid, cm) in enumerate(cols_moved)
        new_board

        for rowid in 1:4
            new_board <<= 4
            new_board |= cm >> 4(4-colid)
        end
    end
    new_board
end

function move(board::UInt64, dir::Dirs)::UInt64
    if dir == left
        new_board = move(board, LEFT)
    elseif dir == right
        new_board = move(board, RIGHT)
    elseif dir == up
        new_board = move_updown(board, LEFT)
    else
        new_board = move_updown(board, RIGHT)
    end

    new_board
end
