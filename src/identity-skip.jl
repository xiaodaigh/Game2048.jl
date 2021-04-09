export IdentitySkip

struct IdentitySkip
   inner
   activation
end

(m::IdentitySkip)(x) = m.activation.(m.inner(x) .+ x)
