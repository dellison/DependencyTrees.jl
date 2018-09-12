"""
    ListBasedConfig

List-based parser configuration as described in Nivre 2008, "Algorithms for Deterministic Incremental Dependency Parsing."
"""
abstract type ListBasedConfig{T} <: TransitionParserConfiguration{T} end

"""
    ListBasedNonProjective{T}

Non-projective list-based parser configuration (
"""
struct ListBasedNonProjective{T} <: ListBasedConfig{T}
    λ1::Vector{Int} # right-headed
    λ2::Vector{Int} # left-headed
    β::Vector{Int}
    A::Vector{T}
end

function ListBasedNonProjective{T}(words::Vector{String}) where {T<:Dependency}
    λ1 = [0]
    λ2 = Int[]
    β = 1:length(words)
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ListBasedNonProjective{T}(λ1, λ2, β, A)
end

arcs(cfg::ListBasedNonProjective) = cfg.A

function leftarc(cfg::ListBasedNonProjective, args...; kwargs...)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    j, β = cfg.β[1], cfg.β[2:end]
    A = copy(cfg.A)
    i != 0 && (A[i] = dep(A[i], args...; head=j, kwargs...))
    ListBasedNonProjective(λ1, [i ; cfg.λ2], [j ; β], A)
end

function rightarc(cfg::ListBasedNonProjective, args...; kwargs...)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    j, β = cfg.β[1], cfg.β[2:end]
    A = copy(cfg.A)
    A[j] = dep(A[j], args...; head=i, kwargs...)
    ListBasedNonProjective(λ1, [i ; cfg.λ2], [j ; β], A)
end

function noarc(cfg::ListBasedNonProjective)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    λ2, β, A = cfg.λ2, cfg.β, cfg.A
    ListBasedNonProjective(λ1, [i ; λ2], β, A)
end

function shift(cfg::ListBasedNonProjective)
    λ1, λ2 = cfg.λ1, cfg.λ2
    i, β = cfg.β[1], cfg.β[2:end]
    ListBasedNonProjective([λ1 ; λ2 ; i], Int[], β, cfg.A)
end

function isfinal(cfg::ListBasedNonProjective)
    return all(a -> head(a) != -1, arcs(cfg)) && length(cfg.λ1) == length(cfg.A) + 1 &&
        length(cfg.λ2) == 0 && length(cfg.β) == 0
end

"""
    static_oracle(::ListBasedNonProjective, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
"""
function static_oracle(::Type{<:ListBasedNonProjective}, graph::DependencyGraph)
    T = eltype(graph)
    g = depargs(T)
    arc(i) = g(graph[i])
    function (cfg::ListBasedNonProjective)
        if length(cfg.λ1) >= 1 && length(cfg.β) >= 1
            i, λ1 = cfg.λ1[end], cfg.λ1[1:end-1]
            j, β = cfg.β[1], cfg.β[2:end]
            if !iszero(i) && head(graph, i) == j
                return LeftArc(arc(i)...)
            elseif head(graph, j) == i
                return RightArc(arc(j)...)
            end
            j_deps = dependents(graph, j)
            if (!(any(x -> x < j, j_deps) && j_deps[1] < i)) && !(head(graph, j) < i)
                return Shift()
            end
        end
        if length(cfg.λ1) == 0
            return Shift()
        end
        return NoArc()
    end
end

import Base.==
==(cfg1::ListBasedNonProjective, cfg2::ListBasedNonProjective) =
    cfg1.λ1 == cfg2.λ1 && cfg1.λ2 == cfg2.λ2 && cfg1.β == cfg2.β && cfg1.A == cfg2.A
