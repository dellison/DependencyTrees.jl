abstract type TrainingOracle{T} end

"""
    StaticOracle(T, oracle_function = static_oracle; transition = typed)

Create a static (deterministic) oracle for mapping parser
configurations (of type T) to gold transitions with reference to
a dependency graph..
"""
struct StaticOracle{T} <: TrainingOracle{T}
    config::T
    oracle_fn::Function
    transition::Function
end

StaticOracle(T, oracle_fn = static_oracle; transition = typed) =
    StaticOracle{typeof(T)}(T, oracle_fn, transition)

struct StaticGoldPairs{T}
    o::Function
    transition::Function
    config::T
    words::Vector{<:AbstractString}
end

function StaticGoldPairs(oracle::StaticOracle, graph::DependencyGraph)
    o = oracle.oracle_fn(oracle.config, graph, oracle.transition)
    StaticGoldPairs(o, oracle.transition, oracle.config, form.(graph))
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

# iterator for (parser_config, gold_transition) pairs
xys(oracle::StaticOracle, graph::DependencyGraph) = StaticGoldPairs(oracle, graph)

xys(oracle::StaticOracle, graphs) =
    reduce(vcat, [collect(xys(oracle, graph)) for graph in graphs])

"""
    DynamicOracle(T, oracle_function = haszerocost; transition = typed)

Create a dynamic oracle for mapping parser configurations (of type T)
to sets of gold transitions with reference to a dependency graph.
See [Goldberg & Nivre, 2012](https://aclweb.org/anthology/C/C12/C12-1059.pdf)
"""
struct DynamicOracle{T} <: TrainingOracle{T}
    config::T
    oracle_fn::Function
    transition::Function
end

DynamicOracle(T, oracle_fn = haszerocost; transition = typed) =
    DynamicOracle{typeof(T)}(T, oracle_fn, transition)

gold_transitions(oracle::DynamicOracle, cfg, gold::DependencyGraph) =
    filter(t -> oracle.oracle_fn(t, cfg, gold), possible_transitions(cfg, gold, oracle.transition))

# only follow optimal transitions, but allow "spurious ambiguity"
choose_next_amb(pred, gold) = pred in gold ? pred : rand(gold)

# explore a possibly nonoptimal transition if filterfunc() is true
choose_next_exp(pred, gold, filterfunc) =
    filterfunc() ? pred : choose_next_amb(pred, gold)

haszerocost(t::TransitionOperator, cfg, gold::DependencyGraph) =
    cost(t, cfg, gold) == 0

hascost(t::TransitionOperator, cfg, gold::DependencyGraph) =
    cost(t, cfg, gold) >= 0

zero_cost_transitions(cfg, gold::DependencyGraph, transition = typed) =
    filter(t -> haszerocost(t, cfg, gold), possible_transitions(cfg, gold, transition))


struct DynamicGoldTransitions{T}
    o::Function          # cfg -> [t, t2, t3]...
    transition::Function 
    predict::Function    # cfg -> t'
    choose::Function     # (t', [tgold...]) -> tgold
    config::T
    gold::DependencyGraph
end

function DynamicGoldTransitions(oracle::DynamicOracle, graph::DependencyGraph;
                                predict=identity, choose=choose_next_amb)
    o = oracle.oracle_fn(oracle.config, graph, oracle.transition)
    DynamicGoldTransitions(o, oracle.transition, predict, choose, oracle.config, graph)
end

Base.IteratorSize(pairs::DynamicGoldTransitions) = Base.SizeUnknown()

import Base.iterate
function Base.iterate(ts::DynamicGoldTransitions)
    C = ts.config
    cfg = initconfig(C, ts.gold)
    pred = ts.predict(cfg)
    gold = zero_cost_transitions(cfg, ts.gold, ts.transition)
    t = ts.choose(pred, gold)
    return ((cfg, gold), t(cfg))
end
function Base.iterate(ts::DynamicGoldTransitions, cfg)
    if isfinal(cfg)
        return nothing
    else
        pred = ts.predict(cfg)
        gold = zero_cost_transitions(cfg, ts.gold, ts.transition)
        t = ts.choose(pred, gold)
        return ((cfg, gold), t(cfg))
    end
end

# iterator for (parser_config, [gold_transitions...])
function xys(oracle::DynamicOracle, gold::DependencyGraph;
             predict=identity, choose=choose_next_amb)
    DynamicGoldTransitions(oracle.oracle_fn, oracle.transition, predict, choose, oracle.config, gold)
end

xys(oracle::DynamicOracle, graphs; predict=identity, choose=choose_next_amb) =
    reduce(vcat, [collect(xys(oracle, graph; predict=predict, choose=choose))
                  for graph in graphs])
