"""
"""
abstract type AbstractOracle{T<:AbstractTransitionSystem, P} end

# this helps for somewhat gracefully e.g. skipping non-projective trees
struct EmptyGoldPairs end

import Base: iterate, IteratorSize, length
IteratorSize(pairs::EmptyGoldPairs) = Base.HasLength()
iterate(pairs::EmptyGoldPairs, state...) = nothing
length(::EmptyGoldPairs) = 0

include("static.jl")
include("dynamic.jl")

include("exploration.jl")
