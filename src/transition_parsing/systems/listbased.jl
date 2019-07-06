"""
    ListBasedNonProjective()

Transition system for list-based non-projective dependency parsing.

Described in Nivre 2008, "Algorithms for Deterministic Incremental Dependency Parsing."
"""
struct ListBasedNonProjective <: AbstractTransitionSystem end

initconfig(s::ListBasedNonProjective, graph::DependencyTree) =
    ListBasedNonProjectiveConfig(graph)
initconfig(s::ListBasedNonProjective, deptype, words) =
    ListBasedNonProjectiveConfig{deptype}(words)

projective_only(::ListBasedNonProjective) = false

transition_space(::ListBasedNonProjective, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), NoArc(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., NoArc(), Shift()]

struct ListBasedNonProjectiveConfig{T} <: AbstractParserConfiguration{T}
    λ1::Vector{Int} # right-headed
    λ2::Vector{Int} # left-headed
    β::Vector{Int}
    A::Vector{T}
end

function ListBasedNonProjectiveConfig{T}(words::Vector{String}) where {T}
    λ1 = [0]
    λ2 = Int[]
    β = 1:length(words)
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ListBasedNonProjectiveConfig{T}(λ1, λ2, β, A)
end

function ListBasedNonProjectiveConfig{T}(gold::DependencyTree) where {T}
    λ1 = [0]
    λ2 = Int[]
    β = 1:length(gold)
    A = [dep(token, head=-1) for token in gold]
    ListBasedNonProjectiveConfig{T}(λ1, λ2, β, A)
end
ListBasedNonProjectiveConfig(gold::DependencyTree) =
    ListBasedNonProjectiveConfig{eltype(gold)}(gold)

buffer(cfg::ListBasedNonProjectiveConfig) = cfg.β

token(cfg::ListBasedNonProjectiveConfig, i) = iszero(i) ? root(deptype(cfg)) :
                                              i == -1   ? noval(deptype(cfg)) :
                                              cfg.A[i]
tokens(cfg::ListBasedNonProjectiveConfig) = cfg.A
tokens(cfg::ListBasedNonProjectiveConfig, is) = [token(cfg, i) for i in is]

function leftarc(cfg::ListBasedNonProjectiveConfig, args...; kwargs...)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    j, β = cfg.β[1], cfg.β[2:end]
    A = copy(cfg.A)
    i != 0 && (A[i] = dep(A[i], args...; head=j, kwargs...))
    ListBasedNonProjectiveConfig(λ1, [i ; cfg.λ2], [j ; β], A)
end

function rightarc(cfg::ListBasedNonProjectiveConfig, args...; kwargs...)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    j, β = cfg.β[1], cfg.β[2:end]
    A = copy(cfg.A)
    A[j] = dep(A[j], args...; head=i, kwargs...)
    ListBasedNonProjectiveConfig(λ1, [i ; cfg.λ2], [j ; β], A)
end

function noarc(cfg::ListBasedNonProjectiveConfig)
    λ1, i = cfg.λ1[1:end-1], cfg.λ1[end]
    λ2, β, A = cfg.λ2, cfg.β, cfg.A
    ListBasedNonProjectiveConfig(λ1, [i ; λ2], β, A)
end

function shift(cfg::ListBasedNonProjectiveConfig)
    λ1, λ2 = cfg.λ1, cfg.λ2
    i, β = cfg.β[1], cfg.β[2:end]
    ListBasedNonProjectiveConfig([λ1 ; λ2 ; i], Int[], β, cfg.A)
end

function isfinal(cfg::ListBasedNonProjectiveConfig)
    return all(a -> head(a) != -1, tokens(cfg)) && length(cfg.λ1) == length(cfg.A) + 1 &&
        length(cfg.λ2) == 0 && length(cfg.β) == 0
end


"""
    static_oracle(::ListBasedNonProjectiveConfig, tree)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
"""
function static_oracle(cfg::ListBasedNonProjectiveConfig, tree, arc=untyped)
    l = i -> arc(tree[i])
    if length(cfg.λ1) >= 1 && length(cfg.β) >= 1
        i, λ1 = cfg.λ1[end], cfg.λ1[1:end-1]
        j, β = cfg.β[1], cfg.β[2:end]
        if !iszero(i) && head(tree, i) == j
            return LeftArc(l(i)...)
        elseif head(tree, j) == i
            return RightArc(l(j)...)
        end
        j_deps = dependents(tree, j)
        if (!(any(x -> x < j, j_deps) && j_deps[1] < i)) && !(head(tree, j) < i)
            return Shift()
        end
    end
    if length(cfg.λ1) == 0
        return Shift()
    end
    return NoArc()
end

# todo?
possible_transitions(cfg::ListBasedNonProjectiveConfig, graph::DependencyTree, arc=untyped) =
    TransitionOperator[static_oracle(cfg, graph, arc)]

==(cfg1::ListBasedNonProjectiveConfig, cfg2::ListBasedNonProjectiveConfig) =
    cfg1.λ1 == cfg2.λ1 && cfg1.λ2 == cfg2.λ2 && cfg1.β == cfg2.β && cfg1.A == cfg2.A

function Base.show(io::IO, c::ListBasedNonProjectiveConfig)
    λ1 = join(c.λ1, ",")
    λ2 = join(c.λ2, ",")
    β = join(c.β, ",")
    print(io, "ListBasedNonProjectiveConfig([$λ1],[$λ2],[$β])\n$(join([join([id(t),form(t),head(t)],'\t') for t in tokens(c)],'\n'))")
end
