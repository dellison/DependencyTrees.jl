"""
    StaticOracle(T, oracle_function = static_oracle; transition = untyped)

Static (deterministic) oracle for mapping parser configurations to
gold transitions.
"""
struct StaticOracle{T<:AbstractTransitionSystem,P,F} <: AbstractOracle{T,P}
    transition_system::T
    oracle_function::F
    transition::P
end

StaticOracle(system, oracle_function=static_oracle; transition=Untyped()) =
    StaticOracle(system, oracle_function, transition)

(oracle::StaticOracle)(tree::DependencyTree; kwargs...) =
    TreeOracle(oracle, tree; kwargs...)

function oracle_state(o::TreeOracle{<:StaticOracle, T}, cfg) where T
    system = o.oracle.transition_system
    tree, transition = o.tree, o.oracle.transition
    oracle = o.oracle.oracle_function
    A = possible_transitions(cfg, tree, transition)
    t = oracle(cfg, tree, transition)
    return GoldState(cfg, A, TransitionOperator[t])
end

transition_system(oracle::StaticOracle) = oracle.transition_system

xys(oracle::StaticOracle, tree::DependencyTree) =
    [(state.cfg, state.G[1]) for state in oracle(tree)]
