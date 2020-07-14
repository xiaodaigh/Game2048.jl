# generate all possible combinations
const VALS = Int8.(1:10)

function gen_all_solved_comb()
    all_comb = Iterators.product([VALS for i in 1:4]...) |> collect ;
    move_combine_compact!.(all_comb)
end

const MOVE_LOOKUP = gen_all_comb()

function move_lookup!(x)
    x .= MOVE_LOOKUP[x[1], x[2], x[3], x[4]]
    x
end