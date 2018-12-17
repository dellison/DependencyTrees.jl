"""
    ArcSwift{T<:Dependency}

Parser configuration for arc-swift transition-based dependency
parsing.
"""
struct ArcSwift{T} <: TransitionParserConfiguration{T}
    "The stack."
    σ::Vector{Int}
    "The word/input buffer."
    β::Vector{Int}
    "The list of arcs."
    A::Vector{T}
end

function ArcSwift{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ArcSwift{T}(σ, β, A)
end

arcs(cfg::ArcSwift) = cfg.A

function leftarc(cfg::ArcSwift, k::Int, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    i = length(cfg.σ) - k + 1
    h, d = cfg.β[1], cfg.σ[i]
    A = copy(cfg.A)
    if d > 0
        A[d] = dep(A[d], args...; head=h, kwargs...)
    end
    σ = cfg.σ[1:i-1]# ; cfg.σ[i+1:end]]
    # println("LA $(cfg.σ) -> $σ")
    ArcSwift(σ, cfg.β, A)
end

function rightarc(cfg::ArcSwift, k::Int, args...; kwargs...)
    # Assert a head-dependent relation between the word on the top of
    # the σ and the word at front of the input buffer; shift the
    # word at the front of the input buffer to the stack.
    i = length(cfg.σ) - k + 1
    h, d = cfg.σ[i], cfg.β[1]
    A = copy(cfg.A)
    A[d] = dep(A[d], args...; head=h, kwargs...)
    σ = [cfg.σ[1:i] ; d]
    β = cfg.β[2:end]
    ArcSwift(σ, β, A)
end

function shift(cfg::ArcSwift)
    # Remove the word from the front of the input buffer and push it
    # onto the stack.
    buf = cfg.β
    ArcSwift([cfg.σ ; buf[1]], buf[2:end], cfg.A)
end

isfinal(cfg::ArcSwift) =
    all(a -> head(a) >= 0, cfg.A) #&& length(cfg.σ) > 0 && length(cfg.β) > 0

"""
    static_oracle(::ArcSwift, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
"""
function static_oracle(::Type{<:ArcSwift}, graph::DependencyGraph)
    T = eltype(graph)
    g = depargs(T)
    arc(i) = g(graph[i])
    function (cfg::ArcSwift)
        S = length(cfg.σ)
        if S >= 1 && length(cfg.β) >= 1
            b = cfg.β[1]
            for k in 1:S
                i = S - k + 1
                s = cfg.σ[i]
                if head(graph, s) == b # (s <-- b)
                    return LeftArc(k, arc(s)...)
                elseif head(graph, b) == s # (s --> b)
                    return RightArc(k, arc(b)...)
                end
            end
        end
        if length(cfg.β) >= 1
            return Shift()
        end
    end
end

import Base.==
==(cfg1::ArcSwift, cfg2::ArcSwift) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A
