"""
    DynamicOracle(system, oracle = haszerocost; transition = untyped)

Dynamic oracle for nondeterministic dependency parsing.
See [Goldberg & Nivre, 2012](https://aclweb.org/anthology/C/C12/C12-1059.pdf).
"""
struct DynamicOracle{T, P} <: AbstractOracle{T, P}
    transition_system::T
    oracle::Function
    transition::P
end

DynamicOracle(T, oracle = haszerocost; transition = untyped) =
    DynamicOracle(T, oracle, transition)

(oracle::DynamicOracle)(tree::DependencyTree; kwargs...) =
    DynamicGoldSearch(oracle, tree; kwargs...)
(oracle::DynamicOracle)(trees; kwargs...) =
    map(tree -> oracle(tree; kwargs...), trees)

gold_transitions(oracle::DynamicOracle, cfg, gold::DependencyTree) =
    filter(t -> oracle.oracle(t, cfg, gold), possible_transitions(cfg, gold, oracle.transition))

initconfig(oracle::DynamicOracle, gold) =
    initconfig(oracle.transition_system, gold)

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

"""
    zero_cost_transitions(cfg, tree)

todo
"""
function zero_cost_transitions(c, gold::DependencyTree, transition=untyped)
    ts = possible_transitions(c, gold, transition)
    filter(t -> haszerocost(t, c, gold), ts)
end

"""
    DynamicGoldState{C}

todo
"""
struct DynamicGoldState{C}
    cfg::C
    A::Vector{TransitionOperator}
    G::Vector{TransitionOperator}
end

function DynamicGoldState(oracle::DynamicOracle, cfg, gold)
    A, G = AG(oracle, cfg, gold)
    DynamicGoldState(cfg, A, G)
end

"""
    next_state(dynamic_state, t)
"""
function next_state(state::DynamicGoldState, t)
    @assert t in state.A "$t is not a legal transition for $(state.cfg)"
    t(state.cfg)
end

"""
    explore(state[, t])

todo
"""
explore(state::DynamicGoldState) = rand(state.A)

"""
    gold_transition(dynamic_state)

"""
gold_transition(state::DynamicGoldState) = rand(state.G)

isoptimal(state::DynamicGoldState, t) = t in state.G

"""
    DynamicGoldSearch

todo
"""
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

Base.iterate(s::DynamicGoldSearch) =
    _iterate(s, initconfig(s.oracle.transition_system, s.tree))

Base.iterate(s::DynamicGoldSearch, cfg) =
    isfinal(cfg) ? nothing : _iterate(s, cfg)

function _iterate(s::DynamicGoldSearch, cfg)
    A, G = AG(s.oracle, cfg, s.tree)
    if isempty(A) || isempty(G)
        error("oracle error on gold tree: $(s.tree) configuration: $cfg\nA: $A\nG: $G")
    end
    t = s.policy() ? s.predict(cfg) : s.choose(s.predict(cfg), G)
    return (DynamicGoldState(cfg, A, G), t(cfg))
end

Base.IteratorSize(pairs::DynamicGoldSearch) = Base.SizeUnknown()

xys(oracle::DynamicOracle, gold::DependencyTree; ks...) =
    [(s.cfg, s.G) for s in DynamicGoldSearch(oracle, gold; ks...)]

xys(oracle::DynamicOracle, trees; kws...) =
    reduce(vcat, [collect(xys(oracle, tree; kws...)) for tree in trees])
