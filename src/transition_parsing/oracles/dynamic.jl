"""
    DynamicOracle(system, oracle = haszerocost; transition = untyped)

Dynamic oracle for nondeterministic dependency parsing.
See [Goldberg & Nivre, 2012](https://aclweb.org/anthology/C/C12/C12-1059.pdf).
"""
struct DynamicOracle{T} <: AbstractOracle{T}
    transition_system::T
    oracle_function
    transition
end

DynamicOracle(T, oracle=haszerocost; transition=Untyped()) =
    DynamicOracle(T, oracle, transition)

transition_system(oracle::DynamicOracle) = oracle.transition_system

(oracle::DynamicOracle)(tree::DependencyTree; kwargs...) =
    TreeOracle(oracle, tree; kwargs...)

function oracle_state(oracle::TreeOracle{<:DynamicOracle, T}, cfg) where T
    transition = oracle.oracle.transition
    oracle_fn = oracle.oracle.oracle_function
    isoptimal = t -> oracle_fn(t, cfg, oracle.tree)
    A = possible_transitions(cfg, oracle.tree, transition)
    G = filter(isoptimal, A)
    return OracleState(cfg, A, G)
end

function gold_transitions(oracle::DynamicOracle, cfg, gold::DependencyTree)
    isoptimal(t) = oracle.oracle_function(t, cfg, gold)
    A = possible_transitions(cfg, gold, oracle.transition)
    return filter(isoptimal, A)
end

initconfig(oracle::DynamicOracle, gold) =
    initconfig(oracle.transition_system, gold)

haszerocost(t::TransitionOperator, cfg, gold::DependencyTree) =
    cost(t, cfg, gold) == 0

hascost(t::TransitionOperator, cfg, gold::DependencyTree) =
    cost(t, cfg, gold) >= 0

"""
    zero_cost_transitions(cfg, tree)

todo
"""
function zero_cost_transitions(cfg, gold_tree, transition=untyped)
    ts = possible_transitions(cfg, gold_tree, transition)
    filter(t -> haszerocost(t, cfg, gold_tree), ts)
end
