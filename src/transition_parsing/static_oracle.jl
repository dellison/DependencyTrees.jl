struct StaticOracle{T} <: TrainingOracle{T}
    config::T
    oracle_fn::Function
end

StaticOracle(T, oracle_fn = static_oracle) =
    StaticOracle{typeof(T)}(T, oracle_fn)

struct StaticGoldPairs{T}
    o::Function
    config::T
    words::Vector{<:AbstractString}
end

function StaticGoldPairs(oracle::StaticOracle, graph::DependencyGraph)
    o = oracle.oracle_fn(oracle.config, graph)
    StaticGoldPairs(o, oracle.config, form.(graph))
end

Base.IteratorSize(pairs::StaticGoldPairs) = Base.SizeUnknown()

import Base.iterate
function Base.iterate(ts::StaticGoldPairs)
    C = ts.config
    cfg = C(ts.words)
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

gold_transitions(oracle::StaticOracle, graph::DependencyGraph) =
    map(last, StaticGoldPairs(oracle, graph))

xys(oracle::StaticOracle, graph::DependencyGraph) = StaticGoldPairs(oracle, graph)

xys(oracle::StaticOracle, graphs) =
    reduce(vcat, [StaticGoldPairs(oracle, graph) for graph in graphs])
