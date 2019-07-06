struct DynamicOracle{T} <: AbstractOracle{T}
    system::T
    oracle_function
    arc
end

"""
    DynamicOracle(system, oracle_function = dynamic_oracle; arc = untyped)

Dynamic oracle for nondeterministic dependency parsing.
See [Goldberg & Nivre, 2012](https://aclweb.org/anthology/C/C12/C12-1059.pdf).
"""
DynamicOracle(system, oracle_function = dynamic_oracle; arc = untyped) =
    DynamicOracle(system, oracle_function, arc)

transition_system(oracle::DynamicOracle) = oracle.system
system(oracle::DynamicOracle) = oracle.system

(oracle::DynamicOracle)(tree::DependencyTree; kwargs...) =
    TreeOracle(oracle, tree; kwargs...)


function oracle_state(gold::TreeOracle{<:DynamicOracle}, cfg)
    arc, oracle = gold.oracle.arc, gold.oracle.oracle_function
    A = possible_transitions(cfg, gold.tree, arc)
    isoptimal = t -> oracle(t, cfg, gold.tree)
    G = filter(isoptimal, A)
    return OracleState(cfg, A, G)
end


function gold_transitions(oracle::DynamicOracle, cfg, gold::DependencyTree)
    isoptimal(t) = oracle.oracle_function(t, cfg, gold)
    A = possible_transitions(cfg, gold, oracle.arc)
    return filter(isoptimal, A)
end

initconfig(oracle::DynamicOracle, gold) =
    initconfig(oracle.system, gold)
