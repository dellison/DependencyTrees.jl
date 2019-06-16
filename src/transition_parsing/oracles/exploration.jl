"""
    AbstractExplorationPolicy

todo
"""
abstract type AbstractExplorationPolicy end

"""
    ExplorationAlways()

Exploration policy, always returns true.
"""
struct ExplorationAlways <: AbstractExplorationPolicy end
(::ExplorationAlways)(args...) = true
policy(::ExplorationAlways, args...) = () -> true
const AlwaysExplore = ExplorationAlways

"""
    ExplorationNever()

Exploration policy, never returns true.
"""
struct ExplorationNever <: AbstractExplorationPolicy end
(::ExplorationNever)(args...) = false
policy(::ExplorationNever, args...) = () -> false
const NeverExplore = ExplorationNever

"""
    ExplorationPolicy(k, p)

Simple exploration policy from Goldberg & Nivre, 2012. Returns true at rate p,
starting at iteration k.
"""
struct ExplorationPolicy <: AbstractExplorationPolicy
    k::Int
    p::Float32

    function ExplorationPolicy(k, p)
        @assert 0 <= p <= 1
        new(k, p)
    end
end

(policy::ExplorationPolicy)(i) =
    i > policy.k && rand(Random.uniform(Float32)) >= 1 - policy.p
policy(p::ExplorationPolicy, i) = () -> p(i)
