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
(p::AlwaysExplore)(state::OracleState) = rand(p.rng, state.A)

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
(p::NeverExplore)(state::OracleState) = rand(p.rng, state.G)

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
(p::ExplorationPolicy)(state::OracleState) =
    rand(p.rng) >= 1 - p.p ? rand(state.A) : rand(state.G)
