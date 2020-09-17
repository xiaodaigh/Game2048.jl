export fingerprint

using Primes

function is_ok(np, known_factors)
    return !any(x->mod(x, np) == 0, @view known_factors[2:end])
end

function all_factors(known_factors)
    fdict = Dict{Int, Bool}()

    for kf in known_factors
        for (f, _) in factor(kf)
            fdict[f] = true
        end
    end
    keys(fdict)
end

function nest_kf(np, known_factors)
    [np1+kf for (np1, kf) in Iterators.product(collect(np .* (0:11)), known_factors)] |> unique
end

function gen_pm()
    primeset = Int[]
    np = nextprime(11*16)
    push!(primeset, np)
    known_factors = nest_kf(np, [0])
    np = nextprime(np+1)
    push!(primeset, np)

    while length(primeset) < 16
        known_factors = nest_kf(np, known_factors)

        allf = all_factors(known_factors)
        bigger_np = nextprime(maximum(allf) + 1)

        np = minimum(setdiff(primes(maximum(primeset)+1, bigger_np), allf))

        push!(primeset, np)
        println(primeset)

        if !is_ok(np, known_factors)
            error("wtf")
        end
    end

    primeset
end

# const primeset = gen_pm()
const primeset = [179, 181, 191, 193, 967, 1741, 2129, 5227, 6389, 11423, 20717, 84223, 140759, 1834901, 6917327, 32892493]

const PRIME_MATRICES = tuple(rotate_mirror(reshape(primeset, 4, 4))...)


function fingerprint(bitboard::Bitboard)
    bb = bitboard_to_array(bitboard)
    maximum(PM -> sum(bb.*PM), PRIME_MATRICES)
end