using Random: GLOBAL_RNG

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
    t = ts.policy(A, G)
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
        t = ts.policy(A, G)
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

"""
    AlwaysExplore()

Policy for always exploring sub-optimal transitions.
"""
struct AlwaysExplore <: AbstractExplorationPolicy
    rng
end
AlwaysExplore() = AlwaysExplore(GLOBAL_RNG)

(::AlwaysExplore)() = true
(p::AlwaysExplore)(A::AbstractVector, _) = _sample(p.rng, A)

Base.show(io::IO, ::AlwaysExplore) = print(io, "AlwaysExplore")

"""
    NeverExplore()

Policy for never exploring sub-optimal transitions.
"""
struct NeverExplore <: AbstractExplorationPolicy
    rng
end
NeverExplore() = NeverExplore(GLOBAL_RNG)

(::NeverExplore)() = false
(p::NeverExplore)(A, G) = _sample(p.rng, G)

Base.show(io::IO, ::NeverExplore) = print(io, "NeverExplore")

"""
    ExplorationPolicy(k, p)

Simple exploration policy from Goldberg & Nivre, 2012. Returns true at rate p.
"""
struct ExplorationPolicy <: AbstractExplorationPolicy
    p::Float64
    rng

    function ExplorationPolicy(p, rng=GLOBAL_RNG)
        @assert 0 <= p <= 1
        new(p, rng)
    end
end

(p::ExplorationPolicy)() =
    rand(p.rng) >= 1 - p.p
(p::ExplorationPolicy)(A::AbstractVector, G::TransitionOperator) = p(A, [G])
(p::ExplorationPolicy)(A::AbstractVector, G::AbstractVector) =
    rand(p.rng) >= 1 - p.p ? rand(A) : rand(G)
