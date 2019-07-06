using Random
using Random: GLOBAL_RNG

abstract type AbstractExplorationPolicy end


"""
    AlwaysExplore()

Policy for always exploring sub-optimal transitions.
"""
struct AlwaysExplore <: AbstractExplorationPolicy
    rng
end
AlwaysExplore() = AlwaysExplore(GLOBAL_RNG)

(::AlwaysExplore)() = true
(p::AlwaysExplore)(A, G) = rand(p.rng, A)
(p::AlwaysExplore)(state::OracleState) = rand(p.rng, state.A)
(::AlwaysExplore)(t::TransitionOperator, g::TransitionOperator) = t

Base.show(io, ::AlwaysExplore) = print(io, "AlwaysExplore")

"""
    ExplorationNever()

Policy for never exploring sub-optimal transitions.
"""
struct NeverExplore <: AbstractExplorationPolicy
    rng
end
NeverExplore() = NeverExplore(GLOBAL_RNG)

(::NeverExplore)() = false
(p::NeverExplore)(A, G) = rand(p.rng, G)
(p::NeverExplore)(state::OracleState) = rand(p.rng, state.G)
(::NeverExplore)(t::TransitionOperator, g::TransitionOperator) = g

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
(p::ExplorationPolicy)(A, G) =
    rand(p.rng) >= 1 - p.p ? rand(A) : rand(G)
(p::ExplorationPolicy)(state::OracleState) =
    rand(p.rng) >= 1 - p.p ? rand(state.A) : rand(state.G)

# policy(p::ExplorationPolicy, i) = () -> p(i)
