"""
    TransitionSystem

Transition system for dependency parsing.
"""
abstract type TransitionSystem end


"""
    ParserState

Parser state representation for transition-based dependency parsing.
"""
abstract type ParserState{T<:Dependency} end

deptype(::Type{<:ParserState{T}}) where T = T
deptype(g::ParserState) = deptype(typeof(g))

include("transitions.jl")
include("arc_standard.jl")
include("arc_eager.jl")
include("arc_hybrid.jl")
include("arc_swift.jl")
include("listbased.jl")
include("oracles.jl")
include("training.jl")
