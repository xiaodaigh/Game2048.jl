# the loop version of loop
function compact!(x)
    @inbounds for i in 1:3
        if x[i] == 0
            for j in i+1:4
                if x[j] != 0
                    tmp = x[j:4]
                    x[j:4] .= 0
                    x[i:i+4-j] .= tmp
                    break;
                end
            end
        end
    end
    x
end

function move_loop!(x)
    # firstly, compact x so that there are no gaps
    # however cells are not yet merged
    compact!(x)

    # now the data is compact; we combine it
    @inbounds if (x[1] != 0) && (x[1] == x[2])
        x[1] += 1
        if (x[3] != 0)  && (x[3] == x[4])
            x[2], x[3], x[4] = x[3] + 1, 0 , 0
        else
            x[2], x[3], x[4] = x[3], x[4], 0
        end
    elseif (x[2] != 0) && (x[2] == x[3])
        x[2] += 1
        x[3], x[4] = x[4], 0
    elseif (x[3] != 0) && (x[3] == x[4])
        x[3] += 1
        x[4] = 0
    end

    x
end
