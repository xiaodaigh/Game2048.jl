# taken from https://github.com/niczky12/medium/blob/b239a849c286b8067e39db57c69e62c34f47aac1/julia/2048.jl
export tui_game

using Game2048Core
using Game2048Core: Bitboard, add_tile, bitboard_to_array, move

using Game2048Core: bitboard_to_array
# Julia command line implementation of the 2048 game

# using Test
import Random
import StatsBase
using Crayons
using Term


function board_cell(value)
    colors = [Term.color.RGBColor(255, 255, 255),
                Term.color.RGBColor(124, 181, 226),
                Term.color.RGBColor(68, 149, 212),
                Term.color.RGBColor(47, 104, 149),
                Term.color.RGBColor(245, 189, 112),
                Term.color.RGBColor(242, 160, 50),
                Term.color.RGBColor(205, 136, 41),
                Term.color.RGBColor(227, 112, 81),
                Term.color.RGBColor(227, 82, 123),
                Term.color.RGBColor(113, 82, 227),
                Term.color.RGBColor(82, 123, 227),
                Term.color.RGBColor(227, 82, 195)]

    if ismissing(value)
        x = ""
    else
        x = "$(2 ^ value)"
    end

    color = Term.color.ANSICode(colors[value+1])
    cell = Panel("$(color.open)$(x)$(color.close)", 
                  justify = :center, width=10, height=3)
    return cell
end


function print_board(board)

    board = bitboard_to_array(board)
    n = size(board, 1)

    rows = Array{Any, 1}(undef, n)
    for row_idx in 1:n
        r = Array{Any, 1}(undef, n)
        for col_idx in 1:n
            r[col_idx] = board_cell(board[row_idx, col_idx])
        end
        rows[row_idx] = *(r...)
    end
    score = sum(2 .^ skipmissing(board))

    p = Panel(
        rows...,
            title="2048_TUI",
            fit=true,
            title_justify=:center,
            title_style="bold green",
            subtitle="Score: $score"
        )
    print(p)
end
# print_board(bitboard::Bitboard) = print_board(bitboard_to_array(bitboard))


print_score(bitboard::Bitboard) = print_score(bitboard_to_array(bitboard))

# see https://stackoverflow.com/questions/56888266/how-to-read-keyboard-inputs-at-every-keystroke-in-julia
function getc1()
    ret = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    ret == 0 || error("unable to switch to raw mode")
    c = read(stdin, Char)
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, false)
    c
end

function tui_game()
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
        # println("\33[2J")
        board = add_tile(board)
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
