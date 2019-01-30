"""
    ArcStandard

Transition system for for Arc-Standard dependency parsing.
"""
struct ArcStandard <: TransitionSystem end

initconfig(s::ArcStandard, graph::DependencyGraph) = ArcStandardState(graph)
initconfig(s::ArcStandard, deptype, words) = ArcStandardState{deptype}(words)

struct ArcStandardState{T} <: ParserState{T}
    σ::Vector{Int}
    β::Vector{Int}
    A::Vector{T}
end

function ArcStandardState{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ArcStandardState{T}(σ, β, A)
end

function ArcStandardState{T}(gold::DependencyGraph) where T
    σ = [0]
    β = collect(1:length(gold))
    A = [dep(word, head=-1) for word in gold]
    ArcStandardState{T}(σ, β, A)
end
ArcStandardState(gold::DependencyGraph) = ArcStandardState{eltype(gold)}(gold)

arcs(cfg::ArcStandardState) = cfg.A

function leftarc(cfg::ArcStandardState, args...; kwargs...)
    # assert a head-dependent relation between the word at the top of
    # the stack and the word directly beneath it; remove the lower
    # word from the stack
    σ, s1, s0 = cfg.σ[1:end-2], cfg.σ[end-1], cfg.σ[end]
    A = copy(cfg.A)
    A[s1] = dep(A[s1], args...; head=s0, kwargs...)
    ArcStandardState([σ ; s0], cfg.β, A)
end

function rightarc(cfg::ArcStandardState, args...; kwargs...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    σ, s1, s0 = cfg.σ[1:end-2], cfg.σ[end-1], cfg.σ[end]
    A = copy(cfg.A)
    A[s0] = dep(A[s0], args...; head=s1, kwargs...)
    ArcStandardState([σ ; s1], cfg.β, A)
end

function shift(state::ArcStandardState)
    # remove the word from the front of the input buffer and push it
    # onto the stack
    b, β = state.β[1], state.β[2:end]
    ArcStandardState([state.σ ; b], β, state.A)
end

isfinal(state::ArcStandardState) =
    length(state.σ) == 1 && state.σ[1] == 0 && length(state.β) == 0


"""
    static_oracle(::ArcStandard, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
"""
function static_oracle(::ArcStandard, graph::DependencyGraph, tr = typed)
    args(i) = tr(graph[i])

    function (cfg::ArcStandardState)
        if length(cfg.σ) >= 2
            s2, s1 = cfg.σ[end-1], cfg.σ[end]
            if has_arc(graph, s1, s2)
                return LeftArc(args(s2)...)
            elseif has_arc(graph, s2, s1)
                if !any(k -> (k in cfg.σ || k in cfg.β), dependents(graph, s1))
                    return RightArc(args(s1)...)
                end
            end
        end
        return Shift()
    end
end


import Base.==
==(cfg1::ArcStandardState, cfg2::ArcStandardState) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A
