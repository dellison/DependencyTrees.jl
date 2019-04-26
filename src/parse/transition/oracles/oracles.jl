abstract type Oracle{T<:AbstractTransitionSystem} end

# this helps for somewhat gracefully e.g. skipping non-projective trees
struct EmptyGoldPairs end
import Base.iterate
Base.iterate(pairs::EmptyGoldPairs, state...) = nothing
Base.IteratorSize(pairs::EmptyGoldPairs) = Base.HasLength()
Base.length(::EmptyGoldPairs) = 0

include("static.jl")
include("dynamic.jl")

include("exploration.jl")
