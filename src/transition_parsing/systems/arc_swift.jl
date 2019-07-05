"""
    ArcSwift()

Parser configuration for arc-swift dependency parsing.

Described in [Qi & Manning 2017](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf).
"""
struct ArcSwift <: AbstractTransitionSystem end

initconfig(::ArcSwift, graph::DependencyTree) = ArcSwiftConfig(graph)
initconfig(::ArcSwift, deptype, words) = ArcSwiftConfig{deptype}(words)

transition_space(::ArcSwift, labels=[]; max_k=5) =
    isempty(labels) ? [LeftArc.(1:max_k)..., RightArc.(1:max_k)..., Shift()] :
    [[LeftArc(k, l) for k in 1:max_k for l in labels]...,
     [RightArc(k, l) for k in 1:max_k for l in labels]...,
     Shift()]

projective_only(::ArcSwift) = true

struct ArcSwiftConfig{T} <: AbstractParserConfiguration{T}
    σ::Vector{Int}
    β::Vector{Int}
    A::Vector{T}
end

function ArcSwiftConfig{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, id, w) for (id, w) in enumerate(words)]
    ArcSwiftConfig{T}(σ, β, A)
end

function ArcSwiftConfig{T}(gold::DependencyTree) where T
    σ = [0]
    β = collect(1:length(gold))
    A = [dep(word, head=-1) for word in gold]
    ArcSwiftConfig{T}(σ, β, A)
end
ArcSwiftConfig(gold::DependencyTree) = ArcSwiftConfig{eltype(gold)}(gold)

stack(cfg::ArcSwiftConfig)  = cfg.σ
buffer(cfg::ArcSwiftConfig) = cfg.β

token(cfg::ArcSwiftConfig, i) = iszero(i) ? root(deptype(cfg)) :
                                i == -1   ? noval(deptype(cfg)) :
                                cfg.A[i]
tokens(cfg::ArcSwiftConfig) = cfg.A
tokens(cfg::ArcSwiftConfig, is) = [token(cfg, i) for i in is if 0 <= i <= length(cfg.A)]

function leftarc(cfg::ArcSwiftConfig, k::Int, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    i = length(cfg.σ) - k + 1
    s, b = cfg.σ[i], cfg.β[1]
    A = copy(cfg.A)
    if s > 0
        A[s] = dep(A[s], args...; head=b, kwargs...)
    end
    ArcSwiftConfig(cfg.σ[1:i-1], cfg.β, A)
end

function rightarc(cfg::ArcSwiftConfig, k::Int, args...; kwargs...)
    # Assert a head-dependent relation between the word on the top of
    # the σ and the word at front of the input buffer; shift the
    # word at the front of the input buffer to the stack.
    i = length(cfg.σ) - k + 1
    s, b = cfg.σ[i], cfg.β[1]
    A = copy(cfg.A)
    A[b] = dep(A[b], args...; head=s, kwargs...)
    ArcSwiftConfig([cfg.σ[1:i] ; b], cfg.β[2:end], A)
end

function shift(cfg::ArcSwiftConfig)
    # Remove the word from the front of the input buffer and push it
    # onto the stack.
    ArcSwiftConfig([cfg.σ ; cfg.β[1]], cfg.β[2:end], cfg.A)
end

isfinal(cfg::ArcSwiftConfig) =
    all(a -> head(a) >= 0, cfg.A) #&& length(cfg.σ) > 0 && length(cfg.β) > 0


"""
    static_oracle(::ArcSwiftConfig, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.

Described in [Qi & Manning 2017](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf).
"""
function static_oracle(cfg::ArcSwiftConfig, tree, arc=untyped)
    l = i -> arc(tree[i])
    S = length(cfg.σ)
    if S >= 1 && length(cfg.β) >= 1
        b = cfg.β[1]
        for k in 1:S
            i = S - k + 1
            s = cfg.σ[i]
            if has_arc(tree, b, s)
                return LeftArc(k, l(s)...)
            elseif has_arc(tree, s, b)
                return RightArc(k, l(b)...)
            end
        end
    end
    return Shift()
end


==(cfg1::ArcSwiftConfig, cfg2::ArcSwiftConfig) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A

# TODO
function possible_transitions(cfg::ArcSwiftConfig, graph::DependencyTree, arc=untyped)
    TransitionOperator[static_oracle(cfg, graph, arc)]
end

Base.show(io::IO, c::ArcSwiftConfig) =
    print(io, "ArcSwiftConfig($(c.σ),$(c.β))\n$(join([join([id(t),form(t),head(t)],'\t') for t in tokens(c)],'\n'))")
