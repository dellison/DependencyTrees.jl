"""
    ArcStandard{T<:Dependency}(words)

Parser configuration for arc-standard transition-based dependency
parsing.
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

# transition operations: leftarc, rightarc, shift

function leftarc(state::ArcStandard, args...; kwargs...)
    # assert a head-dependent relation between the word at the top of
    # the stack and the word directly beneath it; remove the lower
    # word from the stack
    @assert length(state.σ) >= 2
    stack = state.σ
    h, d= stack[end], stack[end-1]
    stack = [stack[1:end-2] ; [h]]
    A = copy(state.A)
    A[d] = dep(A[d], args...; head=h, kwargs...)
    ArcStandard(stack, state.β, A)
end

function rightarc(state::ArcStandard, args...; kwargs...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    @assert length(state.σ) >= 2
    d, h = state.σ[end], state.σ[end-1]
    stack = [state.σ[1:end-2] ; [h]]
    A = copy(state.A)
    A[d] = dep(A[d], args...; head=h, kwargs...)
    ArcStandard(stack, state.β, A)
end

function shift(state::ArcStandard)
    # remove the word from the front of the input buffer and push it
    # onto the stack
    @assert length(state.β) >= 1
    word = state.β[1]
    β = state.β[2:end]
    ArcStandard([state.σ ; word], β, state.A)
end

isfinal(state::ArcStandard) =
    length(state.σ) == 1 && state.σ[1] == 0 && length(state.β) == 0

"""
    static_oracle(::ArcStandard, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
"""
function static_oracle(::Type{<:ArcStandard}, graph::DependencyGraph)
    T = eltype(graph)
    g = depargs(T)
    arc(i) = g(graph[i])
    function (cfg::ArcStandard)
        if length(cfg.σ) >= 2
            s2, s1 = cfg.σ[end-1], cfg.σ[end]
            if head(graph[s2]) == s1 # (s2 <-- s1)
                return LeftArc(arc(s2)...)
            elseif head(graph[s1]) == s2 # (s2 --> s1)
                if all([!(dp in cfg.σ || dp in cfg.β)
                        for dp in dependents(graph, s1)])
                    return RightArc(arc(s1)...)
                end
            end
        end
        return Shift()
    end
end

import Base.==
==(cfg1::ArcStandard, cfg2::ArcStandard) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A
