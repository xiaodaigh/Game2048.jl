# build the lookup
code = [0, 1, 2, 3, 4]

using Base.Iterators

code4 = product(code, code, code, code)

using DataFrames

function makeu(code4)
	c = [code4...]
	d = Dict{Int, Int}()
	upto = 1
	for i in 1:4
		if c[i] == 0
			## do nothing
		elseif haskey(d, c[i])
			c[i] = d[c[i]]
		else
			d[c[i]] = upto
			c[i] = upto
			upto += 1
		end
	end
	c
end

ucode4 = collect([makeu(c) for c in code4]) |> unique

res = [move!([ucode4...]) for ucode4 in ucode4]

a = mapreduce(x->transpose([x...]), vcat, ucode4)
b = mapreduce(x->transpose([x...]), vcat, res)

using CSV, DataFrames
df = DataFrame()
for (i, c) in enumerate(eachcol(hcat(a,b)))
	df[!, Symbol("ok"*string(i))] = c
end
df
CSV.write("d:/data/ok.csv", df)
