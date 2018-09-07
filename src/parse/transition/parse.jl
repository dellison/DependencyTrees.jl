#  TransitionParser

"""
    TransitionParserConfiguration

Parser state representation for transition-based dependency parsing.
"""
abstract type TransitionParserConfiguration{T<:Dependency} end

include("transitions.jl")
include("arc_standard.jl")
include("arc_eager.jl")
include("listbased.jl")

function parse(C::Type{<:TransitionParserConfiguration}, words, oracle)
    cfg = C(words)
    while !isfinal(cfg)
        t = oracle(cfg)
        cfg = t(cfg)
    end
    return DependencyGraph(arcs(cfg))
end
