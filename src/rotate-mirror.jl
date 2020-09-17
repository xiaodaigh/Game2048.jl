export rotate_mirror

const dir_left_rotate = Dict(
    left => down,
    down => right,
    right => up,
    up => left
)

const dir_right_rotate = Dict(
    left => up,
    up => right,
    right => down,
    down => left
)

const dir_180_rotate = Dict(
    left => right,
    right => left,
    up => down,
    down => up
)

const dir_mirror = Dict(
    left => up,
    up=>left,
    down=>right,
    right=>down
)

function rotate_board_dir(board, dir)
    [
        (board, dir),
        (rotl90(board), dir_left_rotate[dir]),
        (rot180(board), dir_180_rotate[dir]),
        (rotr90(board), dir_right_rotate[dir])
    ]
end

function rotate_mirror(board, dir)
    vcat(
        rotate_board_dir(board, dir),
        rotate_board_dir(board |> transpose |> collect, dir_mirror[dir])
    )
end

function rotate_mirror(board)
    tboard = transpose(board) |> collect

    return board,  rotl90(board),  rot180(board),  rotr90(board),
           tboard, rotl90(tboard), rot180(tboard), rotr90(tboard)
end
