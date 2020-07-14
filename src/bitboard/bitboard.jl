# A gameboard is stored on a UInt (64bit)
# where each cell is
using Game2048


const MASK=UInt16(2^16-1)

function col2uint(col::Vector{Int})
    row = zero(UInt16)
    row |= UInt8(col[1])
    for i in 2:4
        row <<= 4
        row |= UInt8(col[i])
    end
    row
end

function make_row_lookup()
    lookup = Vector{UInt16}(undef, 2^16)
    vecs = vec([[v...] for v in Iterators.product(0:15, 0:15, 0:15, 0:15)])
    lookup_arr = deepcopy(vecs)
    move_up!.(lookup_arr)

    idx = col2uint.(vecs)
    vals = col2uint.(lookup_arr)

    for (i, v) in zip(idx, vals)
        lookup[i+1] = v
    end
    lookup
end

function move_up(board::UInt64, lookup)
    new_board = zero(UInt64)

    idx = (board >> 48) & MASK
    new_board |= lookup[idx+1]

    for i in 32:-16:0
        new_board << 16
        idx = (board >> i) & MASK
        new_board |= lookup[idx+1]
    end
    new_board
end
