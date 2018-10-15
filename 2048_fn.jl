function init_game()
    grid = zeros(Int8,4,4)    
    grid[rand(1:4),rand(1:4)] = rand2_1()
    grid[rand(1:4),rand(1:4)] = rand2_1()
    grid
end

rand2_1() = rand() < 0.1 ? 2 : 1

# a function to simulate the move and return a reward
function move!(x, xinc, xstart, xend)
    reward = 0
    @inbounds for i = xstart:xinc:xend # for each row move the left most piece first #if move_row = 1 then i control the row
        if x[i] != 0 # if the position is occupied by a number move it
            # firstly look "behind" to see if there is a number that is the same
            # this is to deal better with situations like 2 2 4 4
            @inbounds for k = i+xinc:xinc:xend
                if x[k] != 0
                    if x[k] == x[i]
                        x[i] += 1
                        reward += 2^x[i]
                        x[k] = 0
                    end
                    break;
                end
            end
            # now place it in the first empty slot
            @inbounds for k = xstart:xinc:i
                if x[k] == 0
                    x[k] = x[i]
                    x[i] = 0
                end
            end
        end
    end
    (x, reward)
end

function move_left!(x)
    move!(x, 1, 1, 4)
end

function move_right!(x)
    move!(x, -1, 4, 1)
end


function move!(grid::Array{T,2}, direction) where T <: Integer
    reward::Int16 = zero(Int16)
    if direction == :left
        for j = 1:4
            #grid[j,:] .= move_left!(grid[j,:])
            (tmp, new_reward) = move_left!(@view grid[j,:])
            reward += new_reward
        end
    elseif direction == :right
        for j = 1:4
            #grid[j,:] .= move_right!(grid[j,:])
            (tmp, new_reward) = move_right!(@view grid[j,:])
            reward += new_reward
        end
    elseif direction == :up
        for j = 1:4
            #grid[:,j] .= move_left!(grid[:,j])
            (tmp, new_reward) = move_left!(@view grid[:,j])
            reward += new_reward
        end
    else
        for j = 1:4
            #grid[:,j] .= move_right!(grid[:,j])
            (tmp, new_reward) = move_right!(@view grid[:,j])
            reward += new_reward
        end
    end
    (grid, reward)
end

function simulate_move!(grid)   
    directions = sample(DIRS, 4 , replace = false)
    for i in 1:3
        d1 = directions[i]
        (grid, ok, cart, two_or_four, reward) = simulate_move!(grid, d1)
        if ok
           return  (grid, true, d1, cart, two_or_four, reward)
        end
    end
    (grid, ok, cart, two_or_four, reward) = simulate_move!(grid, directions[4])
    (grid, ok, directions[4], cart, two_or_four, reward)
end

# assume no need to check for validate moves
function simulate_move!(grid, direction)
    tmp_grid = copy(grid)
    (grid, reward) = move!(grid, direction)
    if all(tmp_grid .== grid)
        return (grid, false, CartesianIndex{2}(-1,-1), -1, 0)
    else
        cart = rand(findall(grid .== 0)) # randomly choose one empty slot
        one_or_two = rand2_1()
        grid[cart] = one_or_two
        return (grid, true, cart, one_or_two, reward)
    end
end

function simulate_game!(grid, lim)
    init_grid = copy(grid)
    seq = Symbol[]::Array{Symbol,1}
    cartarr = CartesianIndex{2}[]
    one_or_two_arr = Int8[]
    reward_vec = Int16[]

    ok = true
    
    while ok
        (grid, ok1, move, cart, one_or_two, new_reward) = simulate_move!(grid)
        ok = ok1 & all(grid .< lim)
        push!(seq, move)
        push!(cartarr, cart)
        push!(one_or_two_arr, one_or_two)
        push!(reward_vec, new_reward)
    end
    (init_grid, grid, seq, cartarr, one_or_two_arr, reward_vec)
end

function simulate_game()
    init = init_game()
    simulate_game!(init, Inf)
end
