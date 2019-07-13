"""
    StaticOracle

Static (deterministic) oracle for mapping parser configurations to
gold transitions.
"""
struct StaticOracle{T<:AbstractTransitionSystem} <: AbstractOracle{T}
    system::T
    oracle_function
    arc
end

"""
    StaticOracle(system, oracle_function=static_oracle; arc=untyped)

Create a static (deterministic) oracle for dependency parsing.

Static oracles deterministically map each parser configuration to
a single gold transition.
"""
StaticOracle(system, oracle_function=static_oracle; arc=untyped) =
    StaticOracle(system, oracle_function, arc)

(oracle::StaticOracle)(tree::DependencyTree; kwargs...) =
    TreeOracle(oracle, tree; kwargs...)

function oracle_state(o::TreeOracle{<:StaticOracle}, cfg)
    system = o.oracle.system
    tree, arc = o.tree, o.oracle.arc
    oracle = o.oracle.oracle_function
    A = possible_transitions(cfg, tree, arc)
    t = oracle(cfg, tree, arc)
    return OracleState(cfg, A, TransitionOperator[t])
end

system(oracle::StaticOracle) = oracle.system

xys(oracle::StaticOracle, tree::DependencyTree) =
    [(state.cfg, state.G[1]) for state in oracle(tree)]
