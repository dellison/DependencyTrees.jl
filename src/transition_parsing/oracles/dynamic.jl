"""
    DynamicOracle(T, oracle_function = haszerocost; transition = typed)

Dynamic oracle for mapping parser configurations (of type T)
to sets of gold transitions with reference to a dependency graph.
See [Goldberg & Nivre, 2012](https://aclweb.org/anthology/C/C12/C12-1059.pdf)
"""
struct DynamicOracle{T} <: Oracle{T}
    transition_system::T
    oracle::Function
    transition::Function
end

DynamicOracle(T, oracle = haszerocost; transition = typed) =
    DynamicOracle(T, oracle, transition)

gold_transitions(oracle::DynamicOracle, cfg, gold::DependencyTree) =
    filter(t -> oracle.oracle(t, cfg, gold), possible_transitions(cfg, gold, oracle.transition))

function AG(oracle::DynamicOracle, cfg, tree)
    A = possible_transitions(cfg, tree, oracle.transition)
    G = filter(t -> oracle.oracle(t, cfg, tree), A)
    return A, G
end

# only follow optimal transitions, but allow "spurious ambiguity"
choose_next_amb(pred, gold) = pred in gold ? pred : rand(gold)

# explore a possibly nonoptimal transition if filterfunc() is true
choose_next_exp(pred, gold, filterfunc) =
    filterfunc() ? pred : choose_next_amb(pred, gold)

haszerocost(t::TransitionOperator, cfg, gold::DependencyTree) =
    cost(t, cfg, gold) == 0

hascost(t::TransitionOperator, cfg, gold::DependencyTree) =
    cost(t, cfg, gold) >= 0

zero_cost_transitions(cfg, gold::DependencyTree, transition = typed) =
    filter(t -> haszerocost(t, cfg, gold), possible_transitions(cfg, gold, transition))

struct DynamicGoldState{C}
    cfg::C
    A::Vector{TransitionOperator}
    G::Vector{TransitionOperator}
end

function DynamicGoldState(oracle::DynamicOracle, cfg, gold)
    A, G = AG(oracle, cfg, gold)
    DynamicGoldState(cfg, A, G)
end

function next_state(state::DynamicGoldState, t)
    @assert t in state.A
    t(state.cfg)
end

function explore(state::DynamicGoldState)
    t = rand(state.A)
    (t, t(state.cfg))
end

function explore(state::DynamicGoldState, t)
    @assert t in state.A
    (t, t(state.cfg))
end

# 
struct DynamicGoldSearch{S,T,P}
    oracle::DynamicOracle{S}
    tree::DependencyTree{T}
    o::Function
    predict::Function
    policy::P
    choose::Function
end
function DynamicGoldSearch(oracle::DynamicOracle, tree::DependencyTree;
                           predict=identity, policy=ExplorationNever(),
                           choose=choose_next_amb)
    if projective_only(oracle.transition_system) && !isprojective(tree)
        EmptyGoldPairs()
    else
        o = cfg -> oracle.oracle(cfg, tree, oracle.transition)
        DynamicGoldSearch(oracle, tree, o, predict, policy, choose)
    end
end

import Base.iterate
Base.iterate(search::DynamicGoldSearch) =
    _iterate(search, initconfig(search.oracle.transition_system, search.tree))
Base.iterate(search::DynamicGoldSearch, cfg) =
    isfinal(cfg) ? nothing : _iterate(search, cfg)
function _iterate(search::DynamicGoldSearch, cfg)
    A, G = AG(search.oracle, cfg, search.tree)
    t = search.policy() ? search.predict(cfg) : search.choose(search.predict(cfg), G)
    return (DynamicGoldState(cfg, A, G), t(cfg))
end

Base.IteratorSize(pairs::DynamicGoldSearch) = Base.SizeUnknown()

xys(oracle::DynamicOracle, gold::DependencyTree; ks...) =
    [(s.cfg, s.G) for s in DynamicGoldSearch(oracle, gold; ks...)]

xys(oracle::DynamicOracle, trees; kws...) =
    reduce(vcat, [collect(xys(oracle, tree; kws...)) for tree in trees])
