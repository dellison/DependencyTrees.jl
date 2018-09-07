"""
    ListBasedConfig

List-based parser configuration as described in Nivre TODO
"""
abstract type ListBasedConfig{T} <: TransitionParserConfiguration{T} end

"""
    ListBasedNonProjective{T}

Non-projective list-based parser configuration (
"""
struct ListBasedNonProjective{T} <: ListBasedConfig{T}
    λ1::Vector{Int}
    λ2::Vector{Int}
    β::Vector{Int}
    A::Vector{T}
end

# ListBasedNonProjective{T}(λ1, λ2, β, A) where T =
#     ListBasedNonProjective{T}(ListConfig{T}(λ1, λ2, β, A))

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
