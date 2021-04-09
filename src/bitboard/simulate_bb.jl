export simulate_bb

using Game2048
using Game2048:move_updown, Bitboard

"""
Makes a random move. It does not add a new tile
"""
function randmove(bitboard::Bitboard)::Bitboard
    dirs = collect(DIRS)

    for i in 4:-1:1
        j = rand(1:i)
        dir = dirs[j]
        new_bitboard = move(bitboard, dir)
        if new_bitboard != bitboard
            return new_bitboard
        end
        dirs[j] = dirs[i]
    end
    return bitboard
end

function simulate_bb(bitboard::Bitboard=initbboard())
    while true
        new_bitboard = randmove(bitboard)
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




