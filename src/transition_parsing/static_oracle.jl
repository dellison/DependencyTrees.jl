struct StaticOracle{T} <: TrainingOracle{T}
    config::T
end

(oracle::StaticOracle)(graph::DependencyGraph) = static_oracle(oracle.config, graph)

# rename?
struct GoldPairs{T}
    o::Function
    config::T
    words::Vector{<:AbstractString}
end

function GoldPairs(oracle::StaticOracle, graph::DependencyGraph)
    o = static_oracle(oracle.config, graph)
    GoldPairs(o, oracle.config, form.(graph))
end

Base.IteratorSize(pairs::GoldPairs) = Base.SizeUnknown()

import Base.iterate
function Base.iterate(ts::GoldPairs)
    C = ts.config
    cfg = C(ts.words)
    t = ts.o(cfg)
    return ((cfg, t), t(cfg))
end
function Base.iterate(ts::GoldPairs, cfg)
    if isfinal(cfg)
        return nothing
    else
        o = ts.o
        gold_t = o(cfg)
        next_cfg = gold_t(cfg)
        return ((cfg, gold_t), next_cfg)
    end
end

gold_transitions(oracle::StaticOracle, graph::DependencyGraph) =
    map(last, GoldTransitions(oracle, graph))

xys(oracle::StaticOracle, graph::DependencyGraph) = GoldPairs(oracle, graph)

xys(oracle::StaticOracle, graphs) =
    reduce(vcat, [GoldPairs(oracle, graph) for graph in graphs])


