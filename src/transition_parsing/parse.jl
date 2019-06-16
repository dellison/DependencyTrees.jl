abstract type AbstractTransitionSystem end

"""
    initconfig(::AbstracyTransitionSystem, ...)

todo
"""
function initconfig end

"""
    transition_space

Returns a vector of all possible transitions for a transition system.
"""
function transition_space end

"""
    projective_only(system)

Returns true for transitions systems that cannot parse nonprojective trees.
"""
function projective_only end

abstract type AbstractParserConfiguration{T<:Dependency} end

"""
    token(cfg, i)

Token at index `i` (1-indexed, with the root node at index 0).
"""
function token end

"""
    tokens(cfg[, is])

Tokens at indices `is` (1-indexed, with the root node at index 0).
"""
function tokens end

deptype(::Type{<:AbstractParserConfiguration{T}}) where T = T
deptype(g::AbstractParserConfiguration) = deptype(typeof(g))

include("transitions.jl")
include("arc_standard.jl")
include("arc_eager.jl")
include("arc_hybrid.jl")
include("arc_swift.jl")
include("listbased.jl")
include("oracles/oracles.jl")
include("features.jl")
