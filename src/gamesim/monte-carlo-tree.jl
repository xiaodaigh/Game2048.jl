using Game2048

export GameTree, get_leaf_nodes, tree_score, find_best_leaf_node, expand_node!
export back_propagate_score!

const C = 1000 # exploration constant

mutable struct GameTree
    board::Game2048.Bitboard
    n::Int
    tot_score::Float64
    pct::Rational{Int}
    parent::Union{Nothing, GameTree}
    children::Vector{GameTree}
    GameTree(board) = new(board, 0, 0, 1//1, nothing, [])
    GameTree(board, parent, pct) = new(board, 0, 0, pct, parent, [])
end

function get_leaf_nodes(gt::GameTree)
    gtarr = GameTree[]
    for child in gt.children
        get_leaf_nodes!(gtarr, child)
    end
    gtarr
end

function get_leaf_nodes!(gtarr::Vector{GameTree}, gt::GameTree)
    if length(gt.children) == 0
        push!(gtarr, gt)
    else
        for child in gt.children
            get_leaf_nodes!(gtarr, child)
        end
    end
    gtarr
end

function tree_score(gt::GameTree, N)
    gt.tot_score/gt.n + C*sqrt(log(N)/gt.n)
end

function find_best_leaf_node(leaf_nodes::Vector{GameTree}, N)
    max_score = 0
    best_leaf_node = leaf_nodes[1]
    for leaf_node in leaf_nodes
        if leaf_node.n == 0
            return leaf_node
        else
            ts = tree_score(leaf_node, N)
            if max_score < ts
                max_score = ts
                best_leaf_node = leaf_node
            end
        end
    end
    best_leaf_node
end

function expand_node!(node)
    # expand the node by populating the children
    for dir in DIRS
        new_board = move(node.board, dir)
        if new_board != node.board
            # count the number of empty spots
            zero_count = count0(new_board)
            for i in 1:zero_count
                new_board_with_new_tile = add_tile(new_board, i, 1)
                push!(node.children, GameTree(new_board_with_new_tile, node, 9//10zero_count))

                new_board_with_new_tile = add_tile(new_board, i, 2)
                push!(node.children, GameTree(new_board_with_new_tile, node, 1//10zero_count))
            end

        end
    end

    node.children
end

function back_propagate_score!(gt::GameTree, score)
    gt.n += 1
    gt.tot_score += score

    if gt.parent !== nothing
        back_propagate_score!(gt.parent, score)
    end
end

function mcts(board)
    gt = GameTree(board)

    # expand the tree node once
    @time expand_node!(gt);

    for i in 1:100
        # go through all leaf nodes and compute score
        leaf_nodes = get_leaf_nodes(gt)

        best_leaf_node = find_best_leaf_node(leaf_nodes, i)

        if best_leaf_node.n == 0
            # not been visited
            # random play to get a score
            # or run a value NN to determine score
            fnl_board = simulate_bb(best_leaf_node.board |> add_tile)
            score = sum(2 .^ bitboard_to_array(fnl_board))

            # back propagate the score
            @time back_propagate_score!(best_leaf_node, score)
        else
            # expand it as it has been visited before
            expand_node!(best_leaf_node)
        end
    end

end