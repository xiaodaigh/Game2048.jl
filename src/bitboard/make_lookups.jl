# the code in here is intend to help make lookups


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
    left_lookup = Vector{UInt16}(undef, 2^16)
    left_reward_lookup = Vector{Int32}(undef, 2^16)
    right_lookup = Vector{UInt16}(undef, 2^16)
    right_reward_lookup = Vector{Int32}(undef, 2^16)

    vecs = vec([[v...] for v in Iterators.product(0:15, 0:15, 0:15, 0:15)])
    left_lookup_arr = deepcopy(vecs)
    right_lookup_arr = deepcopy(vecs)

    for (i, v) in enumerate(vecs)
        idx = rowvec2uint16(v)
        _, reward, _ = move_up!(left_lookup_arr[i])
        left_reward_lookup[idx+1] = reward
        left_lookup[idx+1] = rowvec2uint16(left_lookup_arr[i])

        rla = right_lookup_arr[i]
        _, reward, _ = move_up!(@view rla[4:-1:1])
        right_reward_lookup[idx+1] = reward
        right_lookup[idx+1] = rowvec2uint16(right_lookup_arr[i])
    end

    left_lookup, left_reward_lookup, right_lookup, right_reward_lookup
end
