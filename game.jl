using Game2048
using Game2048: bitboard_to_array
using Colors

WIDTH = 1600
HEIGHT = 1200
BACKGROUND = colorant"grey"

board = initbboard()

CELL_WIDTH = 18*11

function drawnum(i, j, val)
    draw(Rect((CELL_WIDTH+8)j, (CELL_WIDTH+8)i, CELL_WIDTH, CELL_WIDTH), colorant"black", fill=true)
    for v in val:-1:1
        draw(Rect((CELL_WIDTH+8)j+9(11-v), (CELL_WIDTH+8)i+9(11-v), CELL_WIDTH-18(11-v), CELL_WIDTH-18(11-v)), RGB(v/11, v/11, v/11), fill=true)
    end
end

function drawboard(board)
    board_arr = bitboard_to_array(board)
    for i in 1:4, j in 1:4
        val = board_arr[i, j]
        if val != 0
            #draw(Rect(105j, 105i, 100, 100), colorant"black", fill=true)
            drawnum(i, j, val)
        end
    end
end

function on_key_down(g::Game, key)
    global board
    if key == Keys.LEFT
        new_board = move(board, left)
    elseif key == Keys.RIGHT
        new_board = move(board, right)
    elseif key == Keys.DOWN
        new_board = move(board, down)
    elseif key == Keys.UP
        new_board = move(board, up)
    end

    if new_board != board
        board = add_tile(new_board)
    end
end


function update(g::Game)

end

function draw(g::Game)
    clear()
    drawboard(board)
end
