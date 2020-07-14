# this is likely to be slower but easy to see that it's correct

function move_combine_compact!(x)
    pts_scored = 0
    updated = false

    if all(==(0), x)
        return x, pts_scored, updated
    end

    # combine phase
    @inbounds for i in 1:3
        if 0 < x[i] == x[i+1]
            updated = true
            x[i] += 1
            x[i+1] = 0
            pts_scored += 1 << x[i]
        end
    end

    # compact phase i.e. remove 0 in between
    @inbounds if x[1] == 0
        updated = true
        x[1], x[2], x[3], x[4] = x[2], x[3], x[4], 0
    end

    @inbounds if x[2] == 0
        updated = true
        x[2], x[3], x[4] = x[3], x[4], 0
    end

    @inbounds if x[3] == 0
        updated = true
        x[3], x[4] =  x[4], 0
    end
    x, pts_scored, updated
end