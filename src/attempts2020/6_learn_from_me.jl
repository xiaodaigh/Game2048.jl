using Game2048
using Flux
using Flux: crossentropy
using StatsBase: wsample, sample

policy = Chain(
    board -> Float32.(board),
    board -> board ./ maximum(board),
    board -> reshape(board, 4, 4, 1, 1),
    Conv((2,2), 1 => 256, relu),
    Conv((2,2), 256 => 128, relu),
    Conv((2,2), 128 => 64, relu),
    flatten,
    Dense(64, 4),
    softmax
)

const str2dir = Dict{String, Dirs}("l"=>left, "r"=>right, "u"=>up, "d"=>down, "done"=>left)

function loss(x, dir)
    crossentropy(policy(x), dir)
end

function action2vec(dir, val = 1.0)
    a = zeros(Float32, 4)
    a[Int(dir)+1] = val
    a
end

function writeboard(io, board)
    for row in eachrow(board)
        write(io, join(string.(row), ","))
        write(io, "\n")
    end
end

p = Flux.params(policy)
opt = ADAM()


function playme()
    filename = "./data/games$(time()).txt"
    println(filename)
    io = open(filename, "w")
    board = initboard()
    display(board)
    i = ""
    while !haskey(str2dir, i)
        i = readline(stdin)
    end
    while i != "done"
        writeboard(io, board)
        write(io, i)
        write(io, "\n")
        dir = str2dir[i]
        y = action2vec(dir)
        data = [(board, y)]
        Flux.train!(loss, p, data, opt)
        move!(board, dir)
        gen_new_tile!(board)
        display(board)

        i = ""
        while !haskey(str2dir, i)
            i = readline(stdin)
        end
    end
    close(io)
end

playme()

@time  play_game_with_policy(policy; verbose = true, epsilon=0)

