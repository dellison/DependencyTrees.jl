abstract type AbstractExplorationPolicy end
# (policy::AbstractExplorationPolicy)(args...) = error("not implemented lol")

struct ExplorationAlways <: AbstractExplorationPolicy end
(::ExplorationAlways)(args...) = true

struct ExplorationNever <: AbstractExplorationPolicy end
(::ExplorationNever)(args...) = false

"""
    ExplorationPolicy(k, p)

Simple exploration policy from Goldberg & Nivre, 2012.
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
