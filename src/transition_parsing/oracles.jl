"""
    AbstractOracle{T, P}

TODO
"""
abstract type AbstractOracle{T<:AbstractTransitionSystem, P} end

# 

xys(oracle, trees) =
    Base.Iterators.flatten(xys(oracle, tree) for tree in trees)

xys(oracle, tree::DependencyTree; kwargs...) =
    ((state.cfg, state.G) for state in oracle(tree; kwargs...))

"""
   UnparsableTree

TODO
"""
struct UnsearchableTreeOracle
    err
end
Base.IteratorSize(pairs::UnsearchableTreeOracle) = Base.HasLength()
Base.iterate(pairs::UnsearchableTreeOracle, state...) = nothing
Base.length(::UnsearchableTreeOracle) = 0

"""
    OracleState

Temporary state for building a transition parse.
"""
struct OracleState{C}
    "The current configuration."
    cfg::C
    "Possible transitions."
    A::Vector{TransitionOperator}
    "Gold transitions."
    G::Vector{TransitionOperator}
end

include("oracles/exploration.jl")

"""
    TreeOracle

TODO
"""
struct TreeOracle{O<:AbstractOracle, T<:Dependency, E<:AbstractExplorationPolicy}
    oracle::O
    tree::DependencyTree{T}
    policy::E

    function TreeOracle(oracle::AbstractOracle, tree::DependencyTree, policy=NeverExplore())
        if projective_only(transition_system(oracle)) && !isprojective(tree)
            UnsearchableTreeOracle()
        else
            O,T,E = typeof(oracle), deptype(tree), typeof(policy)
            new{O,T,E}(oracle, tree, policy)
        end
    end
end

Base.IteratorSize(o::TreeOracle) = Base.SizeUnknown()

function Base.iterate(o::TreeOracle)
    system, tree, policy = o.oracle.transition_system, o.tree, o.policy
    cfg = initconfig(system, tree)
    state = oracle_state(o, cfg)
    t = policy(state)
    next = t(cfg)
    return (state, next)
end

function Base.iterate(o::TreeOracle, cfg)
    if isfinal(cfg)
        return nothing
    else
        state, policy = oracle_state(o, cfg), o.policy
        t = policy(state)
        next = t(cfg)
        return (state, next)
    end
end

include("oracles/static.jl")
include("oracles/dynamic.jl")
