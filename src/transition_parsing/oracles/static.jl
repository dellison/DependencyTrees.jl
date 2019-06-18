"""
    StaticOracle(T, oracle_function = static_oracle; transition = untyped)

Static (deterministic) oracle for mapping parser configurations to
gold transitions with reference to a gold dependency graph.
"""
struct StaticOracle{T} <: Oracle{T}
    transition_system::T
    oracle::Function
    transition::Function
end

StaticOracle(system, oracle = static_oracle; transition = untyped) =
    StaticOracle(system, oracle, transition)

(oracle::StaticOracle)(tree::DependencyTree; kwargs...) =
    StaticGoldSearch(oracle, tree; kwargs...)
(oracle::StaticOracle)(trees; kwargs...) =
    map(tree -> oracle(tree; kwargs...), trees)

struct StaticGoldState{C,T<:TransitionOperator}
    cfg::C
    t::T
end

import Base.getindex, Base.lastindex
Base.getindex(s::StaticGoldState, i) = 
    i == 1 ? s.cfg :
    i == 2 ? s.t   :
    BoundsError(s, i)
Base.lastindex(::StaticGoldState) = 2

Base.iterate(s::StaticGoldState, state=1) = (s[state], state+1)

==(a::StaticGoldState, b::StaticGoldState) =
    a.cfg == b.cfg && a.t == b.t

AG(s::StaticGoldState) = ([s.t], [s.t])

# TODO rename?
"""
    StaticGoldSearch(oracle, tree)

todo
"""
struct StaticGoldSearch{S<:AbstractTransitionSystem}
    oracle::StaticOracle{S}
    tree::DependencyTree
    o::Function
end

function StaticGoldSearch(oracle::StaticOracle, tree::DependencyTree)
    if projective_only(oracle.transition_system) && !isprojective(tree)
        EmptyGoldPairs()
    else
        o = oracle.oracle(oracle.transition_system, tree, oracle.transition)
        StaticGoldSearch(oracle, tree, o)
    end
end

Base.IteratorSize(s::StaticGoldSearch) = Base.SizeUnknown()

import Base.iterate
function Base.iterate(s::StaticGoldSearch)
    cfg = initconfig(s.oracle.transition_system, s.tree)
    return _iterate(s, cfg)
end
Base.iterate(s::StaticGoldSearch, c) = isfinal(c) ? nothing : _iterate(s, c)

function _iterate(s::StaticGoldSearch, cfg)
    t = s.o(cfg)
    return (StaticGoldState(cfg, t), t(cfg))
end

xys(oracle::StaticOracle, tree::DependencyTree) =
    StaticGoldSearch(oracle, tree)

xys(oracle::StaticOracle, trees) =
    reduce(vcat, [collect(xys(oracle, tree)) for tree in trees])
