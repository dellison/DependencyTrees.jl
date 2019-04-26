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
