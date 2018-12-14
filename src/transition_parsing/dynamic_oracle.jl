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

haszerocost(t::TransitionOperator, cfg::ArcEager, gold::DependencyGraph) =
    cost(t, cfg, gold) == 0

hascost(t::TransitionOperator, cfg::ArcEager, gold::DependencyGraph) =
    cost(t, cfg, gold) >= 0

function cost(t::LeftArc, cfg, gold)
    # left arc cost: num of arcs (k,l',s), (s,l',k) s.t. k ϵ β
    σ, s = σs(cfg)
    b, β = bβ(cfg)
    if has_dependency(gold, b, s)
        0
    else
        count(k -> has_arc(gold, k, s) || has_arc(gold, s, k), β)
    end
end

function cost(t::RightArc, cfg, gold)
    # right arc cost: num of gold arcs (k,l',b), s.t. k ϵ σ or k ϵ β,
    #                 plus num of gold arcs (b,l',k) s.t. k ϵ σ
    σ, s = σs(cfg)
    b, β = bβ(cfg)
    if has_dependency(gold, s, b)
        0
    else
        count(k -> has_arc(gold, k, b), [σ ; β]) + count(k -> has_arc(gold, b, k), σ)
    end
end

function cost(t::Reduce, cfg, gold)
    # num of gold arcs (s,l',k) s.t. k ϵ b|β
    σ, s = σs(cfg)
    count(k -> has_arc(gold, s, k), cfg.β)
end

function cost(t::Shift, cfg, gold)
    # num of gold arcs (k,l',b), (b,l',k) s.t. k ϵ s|σ
    b, β = bβ(cfg)
    count(k -> has_arc(gold, k, b) || has_arc(gold, b, k), cfg.σ)
end

