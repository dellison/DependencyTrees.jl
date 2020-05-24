using Random: GLOBAL_RNG, AbstractRNG

abstract type AbstractOracle{T<:AbstractTransitionSystem} end

initconfig(oracle::AbstractOracle, args...) = initconfig(system(oracle), args...)

struct Oracle{T,O,L}
    system::T
    oracle_function::O
    labelf::L
end

"""
    Oracle(system, oracle_function; label=untyped)

Mapping from parser configurations to gold transitions.
"""
function Oracle(system, oracle_function; label=untyped)
    Oracle(system, oracle_function, label)
end

(oracle::Oracle)(tree::DependencyTree) = OracleSequence(oracle, tree)

(oracle::Oracle)(cfg, tree::DependencyTree) =
    oracle.oracle_function(cfg, tree, oracle.labelf)

initconfig(oracle::Oracle, tree) = initconfig(oracle.system, tree)

function transitions(cfg, gold::DependencyTree, oracle::Oracle)
    A = possible_transitions(cfg, gold, oracle.labelf)
    G = oracle(cfg, gold)
    return A, G
end

"""
    OracleSequence(oracle, tree, policy=NeverExplore())

A "gold" sequence of parser configurations and transitions to build `tree`.

The sequence of transitions is performed according to

`policy` is a function that determines whether or not "incorrect" transitions
are explored. It will be called like so: `policy(
"""
struct OracleSequence{T,P}
    oracle::Oracle{T}
    tree::DependencyTree
    policy::P

    function OracleSequence(oracle::Oracle, tree::DependencyTree, policy=NeverExplore())
        T = oracle.system
        if projective_only(T) && !is_projective(tree)
            UnparsableTree(NonProjectiveGraphError(tree))
        else
            new{typeof(T),typeof(policy)}(oracle, tree, policy)
        end
    end
end

function choose_transition(ts::OracleSequence, cfg)
    A, G = transitions(cfg, ts.tree, ts.oracle)
    t = ts.policy(cfg, A, G)
    return t
end

Base.IteratorSize(ts::OracleSequence) = Base.SizeUnknown()

function Base.iterate(ts::OracleSequence, state=nothing)
    if state === nothing
        state = initconfig(ts.oracle.system, ts.tree)
    end
    if isfinal(state)
        return nothing
    else
        A, G = transitions(state, ts.tree, ts.oracle)
        t = ts.policy(state, A, G)
        return ((state, G), t(state))
    end
end

"""
   UnparsableTree

A dependency tree that an oracle cannot parse.
"""
struct UnparsableTree
    err
end
Base.IteratorSize(pairs::UnparsableTree) = Base.HasLength()
Base.iterate(pairs::UnparsableTree, state...) = nothing
Base.length(::UnparsableTree) = 0

abstract type AbstractExplorationPolicy end

_sample(rng, x::TransitionOperator) = rand(rng, [x])
_sample(rng, x) = rand(rng, x)

passthrough_model(cfg, A, G) = nothing

"""
    AlwaysExplore()

Policy for always exploring sub-optimal transitions.
"""
struct AlwaysExplore{R<:AbstractRNG,M} <: AbstractExplorationPolicy
    rng::R
    model::M
end
AlwaysExplore() = AlwaysExplore(GLOBAL_RNG, passthrough_model)

(::AlwaysExplore)() = true
function (p::AlwaysExplore)(cfg, A::AbstractVector, G)
    t = p.model(cfg, A, G)
    is_possible(t, cfg) ?  t : _sample(p.rng, A)
end

Base.show(io::IO, ::AlwaysExplore) = print(io, "AlwaysExplore")

"""
    NeverExplore()

Policy for never exploring sub-optimal transitions.
"""
struct NeverExplore{R<:AbstractRNG,M} <: AbstractExplorationPolicy
    rng::R
    model::M
end
NeverExplore() = NeverExplore(GLOBAL_RNG, passthrough_model)

(::NeverExplore)() = false
function (p::NeverExplore)(cfg, A, G)
    t = p.model(cfg, A, G)
    is_possible(t, cfg) && t in G ? t : _sample(p.rng, G)
end

Base.show(io::IO, ::NeverExplore) = print(io, "NeverExplore")

"""
    ExplorationPolicy(k, p)

Simple exploration policy from Goldberg & Nivre, 2012. Explores at rate `p`.
"""
struct ExplorationPolicy{R<:AbstractRNG,M} <: AbstractExplorationPolicy
    p::Float64
    rng::R
    model::M

    function ExplorationPolicy(p, rng=GLOBAL_RNG, model=passthrough_model)
        @assert 0 <= p <= 1
        new{typeof(rng),typeof(model)}(p, rng, model)
    end
end

(p::ExplorationPolicy)() =
    rand(p.rng) >= 1 - p.p

(p::ExplorationPolicy)(cfg, A::AbstractVector, G::TransitionOperator) = p(cfg, A, [G])

function (p::ExplorationPolicy)(cfg, A::AbstractVector, G::AbstractVector)
    t = p.model(cfg, A, G)
    explore = rand(p.rng) >= 1 - p.p
    if explore
        return is_possible(t, cfg) ? t : rand(A)
    else
        return rand(G)
    end
end
