# this is the benchmark "winner".
# see ../benchmarks/run-benchmarks.jl
export move_up!
function move_up!(x)
    pts_scored = 0
    updated = false

    if all(==(0), x)
        return x, pts_scored, updated
    end

    # combine phase
    @inbounds for i in 1:3
        if x[i] > 0
            for j in i+1:4
                if x[j] > 0
                    if x[i] == x[j]
                        updated = true
                        x[i] += 1
                        x[j] = 0
                        pts_scored += 1 << x[i]
                    end
                    break # break out of j loop; only combine once
                end
            end
        end
    end

    # compact phase i.e. remove 0 in between
    @inbounds for i in 1:3
        while (x[i] == 0) && any(!=(0), @view x[i+1:4])
            updated = true
            x[i:3] .= @view x[i+1:4]
            x[4] = 0
        end
    end
    x, pts_scored, updated
end
