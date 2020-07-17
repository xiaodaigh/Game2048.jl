function rowvec2uint16(col::Vector{Int})
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

    idx = rowvec2uint16.(vecs)
    vals = rowvec2uint16.(lookup_arr)

    for (i, v) in zip(idx, vals)
        lookup[i+1] = v
    end
    lookup
end