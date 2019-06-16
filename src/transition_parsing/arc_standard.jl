"""
    ArcStandard()

Transition system for for Arc-Standard dependency parsing.

See [Nivre 2004](https://www.aclweb.org/anthology/W04-0308.pdf).
"""
struct ArcStandard <: AbstractTransitionSystem end

initconfig(s::ArcStandard, graph::DependencyTree) = ArcStandardConfig(graph)
initconfig(s::ArcStandard, deptype, words) = ArcStandardConfig{deptype}(words)

projective_only(::ArcStandard) = true

transition_space(::ArcStandard, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., Shift()]

struct ArcStandardConfig{T} <: AbstractParserConfiguration{T}
    σ::Vector{Int}
    β::Vector{Int}
    A::Vector{T}
end

function ArcStandardConfig{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ArcStandardConfig{T}(σ, β, A)
end

function ArcStandardConfig{T}(gold::DependencyTree) where T
    σ = [0]
    β = collect(1:length(gold))
    A = [dep(word, head=-1) for word in gold]
    ArcStandardConfig{T}(σ, β, A)
end
ArcStandardConfig(gold::DependencyTree) = ArcStandardConfig{eltype(gold)}(gold)

token(cfg::ArcStandardConfig, i) = iszero(i) ? root(deptype(cfg)) :
                                   i == -1   ? noval(deptype(cfg)) :
                                   cfg.A[i]
tokens(cfg::ArcStandardConfig) = cfg.A
tokens(cfg::ArcStandardConfig, is) = [token(cfg, i) for i in is if 0 <= i <= length(cfg.A)]

function leftarc(cfg::ArcStandardConfig, args...; kwargs...)
    # assert a head-dependent relation between the word at the top of
    # the stack and the word directly beneath it; remove the lower
    # word from the stack
    σ, s1, s0 = cfg.σ[1:end-2], cfg.σ[end-1], cfg.σ[end]
    A = copy(cfg.A)
    A[s1] = dep(A[s1], args...; head=s0, kwargs...)
    ArcStandardConfig([σ ; s0], cfg.β, A)
end

function rightarc(cfg::ArcStandardConfig, args...; kwargs...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    σ, s1, s0 = cfg.σ[1:end-2], cfg.σ[end-1], cfg.σ[end]
    A = copy(cfg.A)
    A[s0] = dep(A[s0], args...; head=s1, kwargs...)
    ArcStandardConfig([σ ; s1], cfg.β, A)
end

function shift(state::ArcStandardConfig)
    # remove the word from the front of the buffer and push it
    # onto the stack
    b, β = state.β[1], state.β[2:end]
    ArcStandardConfig([state.σ ; b], β, state.A)
end

isfinal(state::ArcStandardConfig) =
    length(state.σ) == 1 && state.σ[1] == 0 && length(state.β) == 0

"""
    static_oracle(::ArcStandard, gold_tree)

Static oracle for arc-standard dependency parsing. Closes over gold trees,
mapping parser configurations to optimal transitions.
"""
function static_oracle(::ArcStandard, gold_tree::DependencyTree, tr = typed)
    args(i) = tr(gold_tree[i])

    function (c::ArcStandardConfig)
        if length(c.σ) >= 2
            s1, s0 = c.σ[end-1], c.σ[end]
            if has_arc(gold_tree, s0, s1)
                return LeftArc(args(s1)...)
            elseif has_arc(gold_tree, s1, s0)
                if !any(k -> (k in c.σ || k in c.β), dependents(gold_tree, s0))
                    return RightArc(args(s0)...)
                end
            end
        end
        return Shift()
    end
end

==(cfg1::ArcStandardConfig, cfg2::ArcStandardConfig) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A

function Base.show(io::IO, c::ArcStandardConfig)
    h = "ArcStandardConfig($(c.σ),$(c.β))"
    fmt(t) = join([id(t),form(t),head(t)],"\t")
    a = join([fmt(t) for t in tokens(c)],'\n')
    print(io, "$h\n$a")
end
