export LEFT, RIGHT, move, add_tile, LEFT_REWARD, RIGHT_REWARD, show, initbboard, display

import Base.show, Base.display

# A gameboard is stored on a UInt (64bit)
# where each cell is
const ROWMASK=UInt16(2^16-1)
const CELLMASK=UInt16(2^4-1)

const LEFT, LEFT_REWARD, RIGHT, RIGHT_REWARD = make_row_lookup()

struct Bitboard
    board::UInt64
end

function initbboard()
    zero(UInt64) |> Bitboard |> add_tile |> add_tile
end

"""
    board2cols(board::UInt64)::Vector{Vector{UInt16}}


Return the columns from a board
"""
function board2cols(bitboard::Bitboard)::Vector{UInt16}
    board = bitboard.board
    # initialise the columns
    cols = zeros(UInt16, 4)

    # take one row at a time
    for row_shift in 48:-16:0
        row = (board >> row_shift) & ROWMASK

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
function move(bitboard::Bitboard, LOOKUP::Vector{UInt16})::Bitboard
    board = bitboard.board

    idx = board >> 48
    new_board = zero(UInt64)
    new_board |= LOOKUP[idx+1]

    for i in 32:-16:0
        new_board <<= 16
        idx = (board >> i) & ROWMASK
        new_board |= LOOKUP[idx+1]
    end
    Bitboard(new_board)
end

function move_updown(bitboard::Bitboard, LOOKUP::Vector{UInt16})::Bitboard
    cols = board2cols(bitboard)
    cols_moved = getindex.(Ref(LOOKUP), cols .+ 1)

    new_board = zero(UInt64)

    # construct the new board by putting the columns in to rows
    for rowid in 1:4
        for colid in 1:4
            new_board <<= 4
            new_board |= (cols_moved[colid] >> 4(4-rowid)) & CELLMASK
        end
    end

    Bitboard(new_board)
end

function move(bitboard::Bitboard, dir::Dirs)::Bitboard
    if dir == left
        new_bitboard = move(bitboard, LEFT)
    elseif dir == right
        new_bitboard = move(bitboard, RIGHT)
    elseif dir == up
        new_bitboard = move_updown(bitboard, LEFT)
    else
        new_bitboard = move_updown(bitboard, RIGHT)
    end

    new_bitboard
end

function count0(bitboard::Bitboard)
    board = bitboard.board
    # firstly count how many empty spots there are
    cnt_empty = 0

    for shift in 0:4:60
        cnt_empty += ((board >> shift) & CELLMASK) == 0
    end

    cnt_empty
end

"""this function should randomly add a one or a 2"""
function add_tile(bitboard::Bitboard)::Bitboard
    cnt_empty = count0(bitboard)
    if cnt_empty == 0
        return bitboard
    end

    board = bitboard.board
    for shift in 0:4:60
        if ((board >> shift) & CELLMASK) == 0
            if rand() <= 1/cnt_empty
                board += rand() < 0.1 ? 2*2^shift : 2^shift
                return Bitboard(board)
            end
            cnt_empty -= 1
        end
    end
    Bitboard(board)
end

function add_tile(bitboard::Bitboard, selected::Integer, two_or_four)
    board = bitboard.board
    i = 0
    for shift in 0:4:60
        if ((board >> shift) & CELLMASK) == 0
            i += 1
            if i == selected
                board += two_or_four*2^shift
                return Bitboard(board)
            end
        end
    end
    Bitboard(board)
end

function bitboard_to_array(bitboard::Bitboard)::Array{Int8, 2}
    board = bitboard.board

    outboard = Array{Int8, 2}(undef, 4, 4)

    rowid = 1
    # take one row at a time
    for row_shift in 48:-16:0
        row = (board >> row_shift) & ROWMASK

        # populate the right cell for each column
        for colid in 4:-1:1
            outboard[rowid, colid] = row & CELLMASK
            row >>= 4
        end
        rowid += 1
    end
    outboard
end

function Base.show(io::IO, bitboard::Bitboard)
    show(io, bitboard_to_array(bitboard))
end

function Base.display(bitboard::Bitboard)
    display(bitboard_to_array(bitboard))
end
