"""
    ArcHybrid

Arc-Hybrid system for transition dependency parsing.

Described in [Kuhlmann et al, 2011](https://www.aclweb.org/anthology/P/P11/P11-1068.pdf),
[Goldberg & Nivre, 2013](https://aclweb.org/anthology/Q/Q13/Q13-1033.pdf).
"""
struct ArcHybrid <: TransitionSystem end

initconfig(s::ArcHybrid, graph::DependencyGraph) = ArcHybridState(graph)
initconfig(s::ArcHybrid, deptype, words) = ArcHybridState{deptype}(words)

struct ArcHybridState{T} <: ParserState{T}
    σ::Vector{Int}
    β::Vector{Int}
    A::Vector{T}
end

function ArcHybridState{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ArcHybridState{T}(σ, β, A)
end

function ArcHybridState{T}(gold::DependencyGraph) where T
    σ = [0]
    β = collect(1:length(gold))
    A = [dep(token, head=-1) for token in gold]
    ArcHybridState{T}(σ, β, A)
end
ArcHybridState(gold::DependencyGraph) = ArcHybridState{eltype(gold)}(gold)

arcs(cfg::ArcHybridState) = cfg.A
deptype(cfg::ArcHybridState) = eltype(cfg.A)

# get σ|s0 as (σ, s0)
function σs0(cfg::ArcHybridState)
    s0 = cfg.σ[end]
    σ = length(cfg.σ) > 1 ? cfg.σ[1:end-1] : Int[]
    return (σ, s0)
end
# σ|s1|s0 as (σ, s1, s0)
function σs1s0(cfg::ArcHybridState)
    s0 = cfg.σ[end]
    temp = length(cfg.σ) > 1 ? cfg.σ[1:end-1] : Int[]
    s1 = temp[end]
    σ = length(temp) > 1 ? temp[1:end-1] : Int[]
    return (σ, s1, s0)
end

# b|β as (b, β)
function bβ(cfg::ArcHybridState)
    b = cfg.β[1]
    β = length(cfg.β) > 1 ? cfg.β[2:end] : Int[]
    return (b, β)
end

# transition operations: leftarc, rightarc, shift

function leftarc(cfg::ArcHybridState, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    s0, b, A = cfg.σ[end], cfg.β[1], copy(cfg.A)
    if s0 > 0
        A[s0] = dep(A[s0], args...; head=b, kwargs...)
    end
    ArcHybridState(cfg.σ[1:end-1], cfg.β, A)
end

function rightarc(cfg::ArcHybridState, args...; kwargs...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    σ, s1, s0 = σs1s0(cfg)
    A = copy(cfg.A)
    if s0 > 0
        A[s0] = dep(A[s0], args...; head=s1, kwargs...)
    end
    ArcHybridState([σ ; s1], cfg.β, A)
end

function shift(cfg::ArcHybridState)
    # remove the word from the front of the input buffer and push it
    # onto the stack
    b, β = cfg.β[1], cfg.β[2:end]
    ArcHybridState([cfg.σ ; b], β, cfg.A)
end

isfinal(cfg::ArcHybridState) = all(a -> head(a) != -1, cfg.A)


function cost(t::LeftArc, cfg::ArcHybridState, gold)
    # number of arcs (s0, d) and (h, s0) for h ϵ H and d ϵ D
    (σ, s0), (b, β) = σs0(cfg), bβ(cfg)
    H = length(σ) > 1 ? [σ[end] ; β] : β
    D = cfg.β
    count(d -> has_arc(gold, s0, d), D) + count(h -> has_arc(gold, h, s0), H)
end

function cost(t::RightArc, cfg::ArcHybridState, gold)
    # number of arcs (s0,d) and (h,s0) for h, d ϵ B
    s0, c = cfg.σ[end], 0
    for (i, k) in enumerate(cfg.β)
        c += has_arc(gold, s0, k)
        c += has_arc(gold, k, s0)
    end
    c
end

function cost(t::Shift, cfg::ArcHybridState, gold)
    # num of arcs (b, d), (h, b) s.t. h ϵ H, d ϵ D
    b = cfg.β[1]
    H, D = length(cfg.σ) > 1 ? cfg.σ[1:end-1] : Int[], cfg.σ
    count(h -> has_arc(gold, h, b), H) + count(d -> has_arc(gold, b, d), D)
end

function possible_transitions(cfg::ArcHybridState, graph::DependencyGraph, tr = typed)
    ops = TransitionOperator[]
    S, B = length(cfg.σ), length(cfg.β)
    if S >= 1
        s = cfg.σ[end]
        if !iszero(s) && S > 1
            push!(ops, RightArc(tr(graph[s])...))
        end
        if B >= 1
            push!(ops, LeftArc(tr(graph[s])...))
        end
    end
    B >= 1 && push!(ops, Shift())
    ops
end


"""
    static_oracle(::ArcHybrid, graph)

Return a static oracle function which maps parser states to gold transition
operations with reference to `graph`.
"""
function static_oracle(::ArcHybrid, graph::DependencyGraph, tr = typed)
    arc(i) = tr(graph[i])

    function (cfg::ArcHybridState)
        if length(cfg.σ) > 0
            σ, s = cfg.σ[1:end-1], cfg.σ[end]
            if length(cfg.β) > 0
                b, β = cfg.β[1], cfg.β[2:end]
                if has_arc(graph, b, s)
                    return LeftArc(arc(s)...)
                end
            end
            if length(σ) > 0
                s2 = σ[end]
                if has_arc(graph, s2, s) && !any(k -> has_arc(graph, s, k), cfg.β)
                    return RightArc(arc(s)...)
                end
            end
        end
        if length(cfg.β) > 0
            return Shift()
        end
    end
end


import Base.==
==(cfg1::ArcHybridState, cfg2::ArcHybridState) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A
