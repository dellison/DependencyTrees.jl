abstract type Oracle{T<:AbstractTransitionSystem} end

# this helps for somewhat gracefully e.g. skipping non-projective trees
struct EmptyGoldPairs end
import Base.iterate
Base.iterate(pairs::EmptyGoldPairs, state...) = nothing
Base.IteratorSize(pairs::EmptyGoldPairs) = Base.HasLength()
Base.length(::EmptyGoldPairs) = 0

"""
    StaticOracle(T, oracle_function = static_oracle; transition = typed)

Static (deterministic) oracle for mapping parser configurations to
gold transitions with reference to a gold dependency graph.
"""
struct StaticOracle{T} <: Oracle{T}
    transition_system::T
    oracle::Function
    transition::Function
end

StaticOracle(system, oracle = static_oracle; transition = typed) =
    StaticOracle(system, oracle, transition)

# iterator for (cfg, gold_transition) pairs
struct StaticGoldPairs{T<:AbstractTransitionSystem}
    o::Function
    transition::Function
    transition_system::T
    graph::DependencyTree
end

function StaticGoldPairs(oracle::StaticOracle, graph::DependencyTree)
    if projective_only(oracle.transition_system) && !isprojective(graph)
        # @warn "skipping projective tree" tree=graph
        EmptyGoldPairs()
    else
        o = oracle.oracle(oracle.transition_system, graph, oracle.transition)
        StaticGoldPairs(o, oracle.transition, oracle.transition_system, graph)
    end
end

Base.IteratorSize(pairs::StaticGoldPairs) = Base.SizeUnknown()

import Base.iterate
function Base.iterate(ts::StaticGoldPairs)
    cfg = initconfig(ts.transition_system, ts.graph)
    t = ts.o(cfg)
    return ((cfg, t), t(cfg))
end
function Base.iterate(ts::StaticGoldPairs, cfg)
    if isfinal(cfg)
        return nothing
    else
        t = ts.o(cfg)
        return ((cfg, t), t(cfg))
    end
end

xys(oracle::StaticOracle, tree::DependencyTree) = StaticGoldPairs(oracle, tree)

xys(oracle::StaticOracle, graphs) =
    reduce(vcat, [collect(xys(oracle, graph)) for graph in graphs])

"""
    DynamicOracle(T, oracle_function = haszerocost; transition = typed)

Dynamic oracle for mapping parser configurations (of type T)
to sets of gold transitions with reference to a dependency graph.
See [Goldberg & Nivre, 2012](https://aclweb.org/anthology/C/C12/C12-1059.pdf)
"""
struct DynamicOracle{T} <: Oracle{T}
    transition_system::T
    oracle::Function
    transition::Function
end

DynamicOracle(T, oracle = haszerocost; transition = typed) =
    DynamicOracle(T, oracle, transition)

gold_transitions(oracle::DynamicOracle, cfg, gold::DependencyTree) =
    filter(t -> oracle.oracle(t, cfg, gold), possible_transitions(cfg, gold, oracle.transition))

# only follow optimal transitions, but allow "spurious ambiguity"
choose_next_amb(pred, gold) = pred in gold ? pred : rand(gold)

# explore a possibly nonoptimal transition if filterfunc() is true
choose_next_exp(pred, gold, filterfunc) =
    filterfunc() ? pred : choose_next_amb(pred, gold)

haszerocost(t::TransitionOperator, cfg, gold::DependencyTree) =
    cost(t, cfg, gold) == 0

hascost(t::TransitionOperator, cfg, gold::DependencyTree) =
    cost(t, cfg, gold) >= 0

zero_cost_transitions(cfg, gold::DependencyTree, transition = typed) =
    filter(t -> haszerocost(t, cfg, gold), possible_transitions(cfg, gold, transition))


# iterator for (cfg, [gold_ts...]) pairs
struct DynamicGoldTransitions{T}
    transition::Function
    o::Function          # cfg -> G
    encodec::Function    # cfg -> X
    encodet::Function    # t -> Y
    decodet::Function    # Y -> t
    predict::Function    # C   -> t'
    choose::Function     # (t', [tgold...]) -> t
    transition_system::T
    gold::DependencyTree
end

function DynamicGoldTransitions(oracle::DynamicOracle, gold::DependencyTree;
                                encodec=identity,encodet=identity,
                                decodet=identity, predict=identity, choose=choose_next_amb)
    if projective_only(oracle.transition_system) && !isprojective(gold)
        # @warn "skipping projective tree" tree=gold
        EmptyGoldPairs()
    else
        o = cfg -> oracle.oracle(cfg, gold, oracle.transition)
        DynamicGoldTransitions(oracle.transition, o, encodec, encodet, decodet,
                               predict, choose, oracle.transition_system, gold)
    end
end

Base.IteratorSize(pairs::DynamicGoldTransitions) = Base.SizeUnknown()

import Base.iterate
function Base.iterate(ts::DynamicGoldTransitions)
    cfg = initconfig(ts.transition_system, ts.gold)
    G = zero_cost_transitions(cfg, ts.gold, ts.transition)
    G′ = ts.encodet(G)
    C = ts.encodec(cfg)
    pred = ts.predict(C)
    t̂ = ts.decodet(pred)
    t = ts.choose(t̂, G)
    return ((C, G′), t(cfg))
end
function Base.iterate(ts::DynamicGoldTransitions, cfg)
    if isfinal(cfg)
        return nothing
    else
        G = zero_cost_transitions(cfg, ts.gold, ts.transition)
        G′ = ts.encodet(G)
        C = ts.encodec(cfg)
        pred = ts.predict(C)
        t̂ = ts.decodet(pred)
        t = ts.choose(t̂, G)
        return ((C, G′), t(cfg))
    end
end

xys(oracle::DynamicOracle, gold::DependencyTree; kwargs...) =
    DynamicGoldTransitions(oracle, gold; kwargs...)

xys(oracle::DynamicOracle, graphs; kwargs...) =
    reduce(vcat, [collect(xys(oracle, graph; kwargs...))
                  for graph in graphs])
