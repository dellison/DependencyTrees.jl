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
