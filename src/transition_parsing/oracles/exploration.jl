using Random
using Random: GLOBAL_RNG

"""
    AbstractExplorationPolicy

todo
"""
abstract type AbstractExplorationPolicy end

# function next_state(policy::AbstractExplorationPolicy, state)
#     try
#         t = policy(state)
#         cfg = t(state.cfg)
#     catch
#     finally
#     end
# end
    

"""
    AlwaysExplore()

Policy for always exploring sub-optimal transitions.
"""
struct AlwaysExplore{R} <: AbstractExplorationPolicy
    rng::R
end
AlwaysExplore() = AlwaysExplore(GLOBAL_RNG)

(::AlwaysExplore)() = true
(p::AlwaysExplore)(A, G) = rand(p.rng, A)
(p::AlwaysExplore)(state::GoldState) = rand(p.rng, state.A)
(::AlwaysExplore)(t::TransitionOperator, g::TransitionOperator) = t

"""
    ExplorationNever()

Policy for never exploring sub-optimal transitions.
"""
struct NeverExplore{R} <: AbstractExplorationPolicy
    rng::R
end
NeverExplore() = NeverExplore(GLOBAL_RNG)

(::NeverExplore)() = false
(p::NeverExplore)(A, G) = rand(p.rng, G)
(p::NeverExplore)(state::GoldState) = rand(p.rng, state.G)
(::NeverExplore)(t::TransitionOperator, g::TransitionOperator) = g

"""
    ExplorationPolicy(k, p)

Simple exploration policy from Goldberg & Nivre, 2012. Returns true at rate p.
"""
struct ExplorationPolicy{R<:AbstractRNG} <: AbstractExplorationPolicy
    p::Float64
    rng::R

    function ExplorationPolicy(p, rng=GLOBAL_RNG)
        @assert 0 <= p <= 1
        new{typeof(rng)}(p, rng)
    end
end

(p::ExplorationPolicy)() =
    rand(p.rng) >= 1 - p.p
(p::ExplorationPolicy)(A, G) =
    rand(p.rng) >= 1 - p.p ? rand(A) : rand(G)
(p::ExplorationPolicy)(state::GoldState) =
    rand(p.rng) >= 1 - p.p ? rand(state.A) : rand(state.G)

# policy(p::ExplorationPolicy, i) = () -> p(i)
