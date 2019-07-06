abstract type AbstractTransitionSystem end

abstract type AbstractParserConfiguration{D} end

deptype(::Type{<:AbstractParserConfiguration{D}}) where D = D
deptype(c::AbstractParserConfiguration) = deptype(typeof(c))

include("systems/transitions.jl")

include("systems/common.jl")
include("systems/arc_standard.jl")
include("systems/arc_eager.jl")
include("systems/arc_hybrid.jl")
include("systems/arc_swift.jl")
include("systems/listbased.jl")

include("systems/features.jl")
