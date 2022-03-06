# taken from https://github.com/niczky12/medium/blob/b239a849c286b8067e39db57c69e62c34f47aac1/julia/2048.jl
export cli_game

using Game2048Core
using Game2048Core: Bitboard, add_tile, bitboard_to_array, move

using Game2048Core: bitboard_to_array
# Julia command line implementation of the 2048 game

# using Test
import Random
import StatsBase
using Crayons

function centered_format(s, size, fill)

    l = length(s)
    right_chars = div(size - l, 2)
    left_chars = size - l - right_chars

    return "$(fill^left_chars)$s$(fill^right_chars)"
end


function print_box_part(value, part::Symbol)

    @assert part ∈ (:top, :middle, :bottom)

    # colours taken from DuckDuckGo's game
    colours = Dict(
        0 => Crayon(bold = true, foreground = :white, background = :white),
        1 => Crayon(bold = true, foreground = :white, background = (124, 181, 226)),
        2 => Crayon(bold = true, foreground = :white, background = (68, 149, 212)),
        3 => Crayon(bold = true, foreground = :white, background = (47, 104, 149)),
        4 => Crayon(bold = true, foreground = :white, background = (245, 189, 112)),
        5 => Crayon(bold = true, foreground = :white, background = (242, 160, 50)),
        6 => Crayon(bold = true, foreground = :white, background = (205, 136, 41)),
        7 => Crayon(bold = true, foreground = :white, background = (227, 112, 81)),
        8 => Crayon(bold = true, foreground = :white, background = (227, 82, 123)),
        9 => Crayon(bold = true, foreground = :white, background = (113, 82, 227)),
        10 => Crayon(bold = true, foreground = :white, background = (82, 123, 227)),
        11 => Crayon(bold = true, foreground = :white, background = (227, 82, 195)),
    )

    if ismissing(value)
        x = ""
    else
        x = "$(2 ^ value)"
    end

    parts = Dict(
        :top => centered_format("-", 12, '-'),
        :middle => "|$(centered_format(x, 10, ' '))|",
        :bottom => centered_format("-", 12, '-')
    )

    print(colours[value], parts[part])
end


function print_board(board)
    n = size(board, 1)
    for row_idx in 1:n
        for part in (:top, :middle, :bottom)
            for col_idx in 1:n
                value = board[row_idx, col_idx]
                print_box_part(value, part)
                print(Crayon(reset = true), " ")
            end
            println()
        end
        println()
    end
end

print_board(bitboard::Bitboard) = print_board(bitboard_to_array(bitboard))


function print_score(board)
    score = sum(2 .^ skipmissing(board))
    n = size(board, 1)

    width = (14 * n) - length("Score: ")

    score_text = centered_format("Score: $score", width, ' ')
    println("\n$score_text\n")
end

print_score(bitboard::Bitboard) = print_score(bitboard_to_array(bitboard))

# see https://stackoverflow.com/questions/56888266/how-to-read-keyboard-inputs-at-every-keystroke-in-julia
function getc1()
    ret = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    ret == 0 || error("unable to switch to raw mode")
    c = read(stdin, Char)
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, false)
    c
end

function cli_game()
    board = Bitboard(UInt(0)) |> add_tile

    input_mapping = Dict(
        'w' => up,
        'd' => right,
        's' => down,
        'a' => left,
        'i' => up,
        'l' => right,
        'k' => down,
        'j' => left
    )

    while true
        if all(bitboard_to_array(board) .!= 0)
            println("You lost!")
            break
            # elseif maximum(skipmissing(board)) == 11
            #     println("YOU WON!")
            #     break
        end

        # clear all output
        println("\33[2J")
        board = add_tile(board)
        print_score(board)
        print_board(board)

        # wait for correct input
        while true
            user_input = getc1()
            if user_input == 'q'
                return
            end
            if user_input ∉ keys(input_mapping)
                continue
            end
            direction = input_mapping[user_input]
            new_board = move(board, direction)
            if new_board != board
                board = new_board
                break
            end
        end
    end

    println("Final score: $(sum(2 .^ bitboard_to_array(board)))")

end

# game(3)

# function getc1()
#     ret = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
#     ret == 0 || error("unable to switch to raw mode")
#     c = read(stdin, Char)
#     ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, false)
#     c
# end

# function getc2()
#     # t = REPL.TerminalMenus.terminal
#     # REPL.TerminalMenus.enableRawMode(t) || error("unable to switch to raw mode")
#     c = Char(REPL.TerminalMenus.readKey(t.in_stream))h
#     # REPL.TerminalMenus.disableRawMode(t)
#     c
# end

# function quit()
#     print("Press q to quit!")
#     while true
#         opt = getc2()
#         if opt == 'q'
#             break
#         else
#             continue
#         end
#     end
# end
