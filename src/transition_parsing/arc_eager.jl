"""
    ArcEager{T<:Dependency}

Parser configuration for arc-eager transition-based dependency
parsing.
"""
struct ArcEager{T} <: TransitionParserConfiguration{T}
    "The stack."
    σ::Vector{Int}
    "The word/input buffer."
    β::Vector{Int}
    "The list of arcs."
    A::Vector{T}
end

function ArcEager{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, id, w) for (id,w) in enumerate(words)]
    ArcEager{T}(σ, β, A)
end

arcs(cfg::ArcEager) = cfg.A

function σs(cfg)
    s = cfg.σ[end]
    if length(cfg.σ) > 1
        σ = cfg.σ[2:end]
    else
        σ = Int[]
    end
    return (σ, s)
end

function bβ(cfg)
    b = cfg.β[1]
    if length(cfg.β) > 1
        β = cfg.β[2:end]
    else
        β = Int[]
    end
    return (b, β)
end

head_assigned(cfg::ArcEager, i) =
    i == 0 || cfg.A[i] != -1

function leftarc(state::ArcEager, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    h, d = state.β[1], state.σ[end]
    A = copy(state.A)
    if d > 0
        A[d] = dep(A[d], args...; head=h, kwargs...)
    end
    ArcEager(state.σ[1:end-1], state.β, A)
end

function rightarc(state::ArcEager, args...; kwargs...)
    # Assert a head-dependent relation between the word on the top of
    # the σ and the word at front of the input buffer; shift the
    # word at the front of the input buffer to the stack.
    h, d = state.σ[end], state.β[1]
    A = copy(state.A)
    A[d] = dep(A[d], args...; head=h, kwargs...)
    β = state.β
    ArcEager([state.σ ; β[1]], β[2:end], A)
end

function Base.reduce(state::ArcEager)
    # Pop the stack.
    ArcEager(state.σ[1:end-1], state.β, state.A)
end

function shift(state::ArcEager)
    # Remove the word from the front of the input buffer and push it
    # onto the stack.
    buf = state.β
    ArcEager([state.σ ; buf[1]], buf[2:end], state.A)
end

isfinal(state::ArcEager) =
    all(a -> head(a) >= 0, state.A)

"""
    static_oracle(::ArcEager, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
"""
function static_oracle(::Type{<:ArcEager}, graph::DependencyGraph)
    T = eltype(graph)
    g = depargs(T)
    arc(i) = g(graph[i])
    function (cfg::ArcEager)
        if length(cfg.σ) >= 1 && length(cfg.β) >= 1
            s, b = cfg.σ[end], cfg.β[1]
            if head(graph, s) == b # (s <-- b)
                return LeftArc(arc(s)...)
            elseif head(graph, b) == s # (s --> b)
                return RightArc(arc(b)...)
            elseif all(w -> w != 0 && head(cfg.A[w]) != -1, [s ; dependents(graph, s)])
                # s's head and all its dependents' heads have been assigned
                return Reduce()
            end
        end
        if length(cfg.β) >= 1
            return Shift()
        end
    end
end

"""
    static_oracle_shift(::ArcEager, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
Similar to the standard static oracle, but always Shift when ambiguity
is present.
"""
function static_oracle_shift(::Type{<:ArcEager}, graph::DependencyGraph)
    T = eltype(graph)
    g = depargs(T)
    arc(i) = g(graph[i])
    function (cfg::ArcEager)
        has_r_children, must_reduce = false, false
        (σ, s), (b, β) = σs(cfg), bβ(cfg)
        must_reduce = false
        for i in cfg.σ
            if has_arc(graph, i, b) || has_arc(graph, b, i)
                must_reduce = true
                break
            elseif !head_assigned(cfg, i)
                break
            end
        end
        has_right_children = any(k -> has_arc(graph, s, k), cfg.β)
        if head(graph, s) == b
            return LeftArc(arc(s)...)
        elseif head(graph, b) == s
            return RightArc(arc(b)...)
        elseif !must_reduce || (s != 0 && head(cfg.A[s]) == -1) || has_right_children
            return Shift()
        else
            return Reduce()
        end
    end
end

"""
    static_oracle_reduce(::ArcEager, graph)

Return a training oracle function which returns gold transition
operations from a parser configuration with reference to `graph`.
Similar to the standard static oracle, but always Reduce when
ambiguity is present.
"""
function static_oracle_reduce(::Type{<:ArcEager}, graph::DependencyGraph)
    T = eltype(graph)
    g = depargs(T)
    arc(i) = g(graph[i])
    function (cfg::ArcEager)
        if length(cfg.σ) >= 1 && length(cfg.β) >= 1
            s, b = cfg.σ[end], cfg.β[1]
            if all(w -> w != 0 && head(cfg.A[w]) != -1, [s ; dependents(graph, s)])
                return Reduce()
            elseif !iszero(s) && head(graph, s) == b # (s <-- b)
                return LeftArc(arc(s)...)
            elseif head(graph, b) == s # (s --> b)
                return RightArc(arc(b)...)
            end
        end
        if length(cfg.β) >= 1
            return Shift()
        end
    end
end

import Base.==
==(cfg1::ArcEager, cfg2::ArcEager) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A

# see figure 2 in goldberg & nivre 2012 "a dynamic oracle..."
function possible_transitions(cfg::ArcEager, graph::DependencyGraph)
    g = depargs(eltype(graph))
    ops = TransitionOperator[]
    stacksize, bufsize = length(cfg.σ), length(cfg.β)
    if stacksize >= 1
        σ, s = σs(cfg)
        if bufsize >= 1
            if !iszero(s)
                h = head(cfg.A[s])
                if !any(k -> id(k) == h, cfg.A)
                    push!(ops, LeftArc(g(graph[s])...))
                end
            end
            push!(ops, RightArc(g(graph[cfg.β[1]])...))
        end
        if !iszero(s)
            h = head(cfg.A[s])
            if any(k -> id(k) == h, cfg.A)
                push!(ops, Reduce())
            end
        end
    end
    if bufsize > 1
        push!(ops, Shift())
    end
    return ops
end
