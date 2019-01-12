# Implementation of the dynamic oracle for arc eager dependency
# parsing, as described in Goldberg & Nivre 2012.

struct DynamicOracle{T} <: TrainingOracle{T}
    config::T
    oracle_fn::Function
end

DynamicOracle(T, oracle_fn = haszerocost) =
    DynamicOracle{typeof(T)}(T, oracle_fn)

gold_transitions(oracle::DynamicOracle, cfg, gold::DependencyGraph) =
    filter(t -> oracle.oracle_fn(t, cfg, gold), possible_transitions(cfg, gold))

# only follow optimal transitions, but allow "spurious ambiguity"
choose_next_amb(pred, gold) = pred in gold ? pred : rand(gold)

# explore a possibly nonoptimal transition if filterfunc() is true
choose_next_exp(pred, gold, filterfunc) =
    filterfunc() ? pred : choose_next_amb(pred, gold)

haszerocost(t::TransitionOperator, cfg, gold::DependencyGraph) =
    cost(t, cfg, gold) == 0

hascost(t::TransitionOperator, cfg, gold::DependencyGraph) =
    cost(t, cfg, gold) >= 0

zero_cost_transitions(cfg, gold::DependencyGraph) =
    filter(t -> haszerocost(t, cfg, gold), possible_transitions(cfg, gold))


struct DynamicGoldTransitions{T}
    o::Function       # cfg -> [t, t2, t3]...
    predict::Function # cfg -> t'
    choose::Function  # (t', [tgold...]) -> tgold
    config::T
    gold::DependencyGraph
end

function DynamicGoldTransitions(oracle::DynamicOracle, graph::DependencyGraph;
                                predict=identity, choose=choose_next_amb)
    o = oracle.oracle_fn(oracle.config, graph)
    DynamicGoldTransitions(o, predict, choose, oracle.config, graph)
end

Base.IteratorSize(pairs::DynamicGoldTransitions) = Base.SizeUnknown()

import Base.iterate
function Base.iterate(ts::DynamicGoldTransitions)
    C = ts.config
    cfg = initconfig(C, ts.gold)
    pred = ts.predict(cfg)
    gold = zero_cost_transitions(cfg, ts.gold)
    t = ts.choose(pred, gold)
    return ((cfg, gold), t(cfg))
end
function Base.iterate(ts::DynamicGoldTransitions, cfg)
    if isfinal(cfg)
        return nothing
    else
        pred = ts.predict(cfg)
        gold = zero_cost_transitions(cfg, ts.gold)
        t = ts.choose(pred, gold)
        return ((cfg, gold), t(cfg))
    end
end

function xys(oracle::DynamicOracle, gold::DependencyGraph;
             predict=identity, choose=choose_next_amb)
    DynamicGoldTransitions(oracle.oracle_fn, predict, choose, oracle.config, gold)
end
