"""
    ListBasedNonProjective

Transition system for list-based non-projective dependency parsing.

Described in Nivre 2008, "Algorithms for Deterministic Incremental Dependency Parsing."
"""
struct ListBasedNonProjective <: AbstractTransitionSystem end

initconfig(s::ListBasedNonProjective, graph::DependencyTree) =
    ListBasedNonProjectiveState(graph)
initconfig(s::ListBasedNonProjective, deptype, words) =
    ListBasedNonProjectiveState{deptype}(words)

projective_only(::ListBasedNonProjective) = false

struct ListBasedNonProjectiveState{T} <: AbstractParserConfiguration{T}
    λ1::Vector{Int} # right-headed
    λ2::Vector{Int} # left-headed
    β::Vector{Int}
    A::Vector{T}
end

function ListBasedNonProjectiveState{T}(words::Vector{String}) where {T}
    λ1 = [0]
    λ2 = Int[]
    β = 1:length(words)
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ListBasedNonProjectiveState{T}(λ1, λ2, β, A)
end

function ListBasedNonProjectiveState{T}(gold::DependencyTree) where {T}
    λ1 = [0]
    λ2 = Int[]
    β = 1:length(gold)
    A = [dep(token, head=-1) for token in gold]
    ListBasedNonProjectiveState{T}(λ1, λ2, β, A)
end
ListBasedNonProjectiveState(gold::DependencyTree) =
    ListBasedNonProjectiveState{eltype(gold)}(gold)

arcs(cfg::ListBasedNonProjectiveState) = cfg.A

function leftarc(cfg::ListBasedNonProjectiveState, args...; kwargs...)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    j, β = cfg.β[1], cfg.β[2:end]
    A = copy(cfg.A)
    i != 0 && (A[i] = dep(A[i], args...; head=j, kwargs...))
    ListBasedNonProjectiveState(λ1, [i ; cfg.λ2], [j ; β], A)
end

function rightarc(cfg::ListBasedNonProjectiveState, args...; kwargs...)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    j, β = cfg.β[1], cfg.β[2:end]
    A = copy(cfg.A)
    A[j] = dep(A[j], args...; head=i, kwargs...)
    ListBasedNonProjectiveState(λ1, [i ; cfg.λ2], [j ; β], A)
end

function noarc(cfg::ListBasedNonProjectiveState)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    λ2, β, A = cfg.λ2, cfg.β, cfg.A
    ListBasedNonProjectiveState(λ1, [i ; λ2], β, A)
end

function shift(cfg::ListBasedNonProjectiveState)
    λ1, λ2 = cfg.λ1, cfg.λ2
    i, β = cfg.β[1], cfg.β[2:end]
    ListBasedNonProjectiveState([λ1 ; λ2 ; i], Int[], β, cfg.A)
end

function isfinal(cfg::ListBasedNonProjectiveState)
    return all(a -> head(a) != -1, arcs(cfg)) && length(cfg.λ1) == length(cfg.A) + 1 &&
        length(cfg.λ2) == 0 && length(cfg.β) == 0
end


"""
    static_oracle(::ListBasedNonProjectiveState, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
"""
function static_oracle(::ListBasedNonProjective, graph::DependencyTree, tr = typed)
    arc(i) = tr(graph[i])

    function (cfg::ListBasedNonProjectiveState)
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
==(cfg1::ListBasedNonProjectiveState, cfg2::ListBasedNonProjectiveState) =
    cfg1.λ1 == cfg2.λ1 && cfg1.λ2 == cfg2.λ2 && cfg1.β == cfg2.β && cfg1.A == cfg2.A
