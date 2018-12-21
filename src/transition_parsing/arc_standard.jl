"""
    ArcStandard{T<:Dependency}(words)

Parser configuration for arc-standard dependency parsing.
"""
struct ArcStandard{T<:Dependency} <: TransitionParserConfiguration{T}
    σ::Vector{Int}
    β::Vector{Int}
    A::Vector{T}
end

function ArcStandard{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ArcStandard{T}(σ, β, A)
end

arcs(cfg::ArcStandard) = cfg.A

function leftarc(cfg::ArcStandard, args...; kwargs...)
    # assert a head-dependent relation between the word at the top of
    # the stack and the word directly beneath it; remove the lower
    # word from the stack
    σ, s1, s0 = cfg.σ[1:end-2], cfg.σ[end-1], cfg.σ[end]
    A = copy(cfg.A)
    A[s1] = dep(A[s1], args...; head=s0, kwargs...)
    ArcStandard([σ ; s0], cfg.β, A)
end

function rightarc(cfg::ArcStandard, args...; kwargs...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    σ, s1, s0 = cfg.σ[1:end-2], cfg.σ[end-1], cfg.σ[end]
    A = copy(cfg.A)
    A[s0] = dep(A[s0], args...; head=s1, kwargs...)
    ArcStandard([σ ; s1], cfg.β, A)
end

function shift(state::ArcStandard)
    # remove the word from the front of the input buffer and push it
    # onto the stack
    b, β = state.β[1], state.β[2:end]
    ArcStandard([state.σ ; b], β, state.A)
end

isfinal(state::ArcStandard) =
    length(state.σ) == 1 && state.σ[1] == 0 && length(state.β) == 0

"""
    static_oracle(::ArcStandard, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
"""
function static_oracle(::Type{<:ArcStandard}, graph::DependencyGraph)
    g = depargs(eltype(graph))
    args(i) = g(graph[i])

    function (cfg::ArcStandard)
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
==(cfg1::ArcStandard, cfg2::ArcStandard) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A
