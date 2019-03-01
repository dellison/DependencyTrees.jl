abstract type AbstractTransitionSystem end

abstract type AbstractParserConfiguration{T<:Dependency} end

deptype(::Type{<:AbstractParserConfiguration{T}}) where T = T
deptype(g::AbstractParserConfiguration) = deptype(typeof(g))

include("transitions.jl")
include("arc_standard.jl")
include("arc_eager.jl")
include("arc_hybrid.jl")
include("arc_swift.jl")
include("listbased.jl")
include("oracles.jl")
include("training.jl")
include("features.jl")
