module TransitionParsing

export
    ArcEager, ArcStandard, ArcHybrid, ArcSwift, ListBasedNonProjective,

    Oracle,
    static_oracle, dynamic_oracle, static_oracle_prefer_shift,
    typed, untyped,
    
    AlwaysExplore, NeverExplore, ExplorationPolicy,

    initconfig, isfinal, possible_transitions, transition_space,
    stacktoken, buffertoken

import Base.reduce

import Random.AbstractRNG
import Random.GLOBAL_RNG

import ..Token, ..DependencyTree, ..deptree, ..ROOT, ..deps, ..token, 
    ..has_arc, ..has_head, ..is_projective, ..leftdeps, ..rightdeps,
    ..NonProjectiveGraphError

"""
    untyped(token)

Create an arc without a dependency label.
"""
untyped(token) = ()

"""
    typed(token)

Create an arc with a labeled dependency relation.
"""
typed(token) = (token.label,)

abstract type AbstractTransitionSystem end

include("systems/common.jl")
include("systems/arc_standard.jl")
include("systems/arc_eager.jl")
include("systems/arc_hybrid.jl")
include("systems/arc_swift.jl")
include("systems/listbased.jl")

include("oracles.jl")

end # module