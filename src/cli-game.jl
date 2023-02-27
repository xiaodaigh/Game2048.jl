# taken from https://github.com/niczky12/medium/blob/b239a849c286b8067e39db57c69e62c34f47aac1/julia/2048.jl
export cli_game

using Game2048Core
using Game2048Core: Bitboard, add_tile, bitboard_to_array, move

using Game2048Core: bitboard_to_array
# Julia command line implementation of the 2048 game

# using Test
import Random
import StatsBase
using Terming
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
    box = [:ROUNDED, :SQUARE, :HEAVY, :HEAVY, :DOUBLE, :SQUARE, :HEAVY, :SQUARE, :HEAVY, :SQUARE, :HEAVY, :DOUBLE ]
    linecolor = ["white", "cyan", "cyan", "blue", "blue", "yellow", "yellow", "red", "red", "green", "green", "magenta"]

    if (value == 0) || ismissing(value)
        x = " "
    else
        x = "$(2 ^ value)"
    end

    color = Term.color.ANSICode(colors[value+1])
    cell = Panel("$(color.open)$(x)$(color.close)",
                  justify=:center, width=10, height=3,
                  box=box[value+1], style=linecolor[value+1])
    return cell
end


function print_board(board)
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
            title_style="default",
            box = :HORIZONTALS,
            subtitle="Score: $score",
            subtitle_justify=:right
        )
    print(p)
end
print_board(bitboard::Bitboard) = print_board(bitboard_to_array(bitboard))

function print_help()
    tb = TextBox("Control: WASD or IJKL, Quit: 'ESC'")
    println(tb)
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

    # clear all output
    # println("\33[2J")
    board = add_tile(board)

    # set term size and clear
    Terming.displaysize(20, 75);
    Terming.alt_screen(true)
    print_help()
    print_board(board)

    # enable raw mode
    Terming.raw!(true)
    event = nothing

    playing = true
    while playing
        if event == Terming.KeyPressedEvent(Terming.ESC)
            playing = false
            break
        end
        if all(bitboard_to_array(board) .!= 0)
            println("You have no move left!")
            println("Press ESC to end the game")
            playing = false
        end

        # read in_stream
        sequence = Terming.read_stream()
        # parse in_stream sequence to event
        event = Terming.parse_sequence(sequence)
        if isa(event, Terming.KeyPressedEvent)
            if haskey(input_mapping, event.key)
                direction = input_mapping[event.key]
                new_board = move(board, direction)
                if new_board != board
                    board = new_board
                    Terming.clear()
                    board = add_tile(board)
                    print_help()
                    print_board(board)
                end
            end
        end
    end
    # Clear terminal UI
    Terming.alt_screen(false)
    Terming.clear()
    Terming.raw!(false)

    p = Panel("Well Done!\nScore: [green]$(sum(2 .^ bitboard_to_array(board)))", width = 18, justify=:center)
    print(p)
end