"""
    ArcEager{T<:Dependency}

Parser configuration for arc-eager dependency parsing.

Described in [Nivre 2003](http://stp.lingfil.uu.se/~nivre/docs/iwpt03.pdf),
[Nivre 2008](https://www.aclweb.org/anthology/J/J08/J08-4003.pdf).
"""
struct ArcEager{T} <: TransitionParserConfiguration{T}
    σ::Vector{Int}
    β::Vector{Int}
    A::Vector{T}
end

function ArcEager{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, i, word) for (i, word) in enumerate(words)]
    ArcEager{T}(σ, β, A)
end

arcs(cfg::ArcEager) = cfg.A

function σs(cfg::ArcEager)
    s = cfg.σ[end]
    σ = length(cfg.σ) > 1 ? cfg.σ[2:end] : Int[]
    return (σ, s)
end

function bβ(cfg::ArcEager)
    b = cfg.β[1]
    β = length(cfg.β) > 1 ? cfg.β[2:end] : Int[]
    return (b, β)
end

function leftarc(cfg::ArcEager, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    s, b, A = cfg.σ[end], cfg.β[1], copy(cfg.A)
    if s > 0
        A[s] = dep(A[s], args...; head=b, kwargs...)
    end
    ArcEager(cfg.σ[1:end-1], cfg.β, A)
end

function rightarc(cfg::ArcEager, args...; kwargs...)
    # Assert a head-dependent relation between the word on the top of
    # the σ and the word at front of the input buffer; shift the
    # word at the front of the input buffer to the stack.
    (σ, s), (b, β), A = σs(cfg), bβ(cfg), copy(cfg.A)
    A[b] = dep(A[b], args...; head=s, kwargs...)
    ArcEager([cfg.σ ; b], β, A)
end

function Base.reduce(cfg::ArcEager)
    # Pop the stack.
    ArcEager(cfg.σ[1:end-1], cfg.β, cfg.A)
end

function shift(cfg::ArcEager)
    # Remove the word from the front of the input buffer and push it
    # onto the stack.
    (b, β) = bβ(cfg)
    ArcEager([cfg.σ ; b], β, cfg.A)
end

isfinal(cfg::ArcEager) = all(a -> head(a) >= 0, cfg.A)
hashead(cfg::ArcEager, k) = head(cfg.A[k]) != -1

"""
    static_oracle(::ArcEager, graph)

Return a static oracle function which maps parser states to gold transition
operations with reference to `graph`.

Described in [Goldberg & Nivre 2012](https://www.aclweb.org/anthology/C/C12/C12-1059.pdf).
"""
function static_oracle(::Type{<:ArcEager}, graph::DependencyGraph)
    g = depargs(eltype(graph))
    args(i) = g(graph[i])
    gold_arc(a, b) = has_arc(graph, a, b)

    function (cfg::ArcEager)
        if length(cfg.σ) >= 1 && length(cfg.β) >= 1
            s, b = cfg.σ[end], cfg.β[1]
            if gold_arc(b, s)
                return LeftArc(args(s)...)
            elseif gold_arc(s, b)
                return RightArc(args(b)...)
            elseif all(k -> k > 0 && hashead(cfg, k), [s ; dependents(graph, s)])
                return Reduce()
            end
        end
        return Shift()
    end
end

"""
    static_oracle_shift(::ArcEager, graph)

Return a static oracle function which maps parser states to gold
transition operations with reference to `graph`.  Similar to the
standard static oracle, but always Shift when ambiguity is present.

Described in [Qi & Manning 2007](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf).
"""
function static_oracle_shift(::Type{<:ArcEager}, graph::DependencyGraph)
    g = depargs(eltype(graph))
    args(i) = g(graph[i])
    gold_arc(a, b)= has_arc(graph, a, b)

    function (cfg::ArcEager)
        (σ, s), (b, β) = σs(cfg), bβ(cfg)
        if gold_arc(b, s)
            return LeftArc(args(s)...)
        elseif gold_arc(s, b)
            return RightArc(args(b)...)
        end
        must_reduce = !any(k -> gold_arc(k, b) || gold_arc(b, k), cfg.σ) ||
            all(k -> k == 0 || hashead(cfg, k), cfg.σ)
        has_right_children = any(k -> gold_arc(s, k), cfg.β)
        if ! must_reduce || s > 0 && !hashead(cfg, s) || has_right_children
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

Described in [Qi & Manning 2007](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf).
"""
function static_oracle_reduce(::Type{<:ArcEager}, graph::DependencyGraph)
    g = depargs(eltype(graph))
    args(i) = g(graph[i])
    gold_arc(a, b) = has_arc(graph, a, b)

    function (cfg::ArcEager)
        if length(cfg.σ) >= 1 && length(cfg.β) >= 1
            s, b = cfg.σ[end], cfg.β[1]
            if all(k -> k > 0 && hashead(cfg, k), [s ; dependents(graph, s)])
                return Reduce()
            elseif !iszero(s) && gold_arc(b, s)
                return LeftArc(args(s)...)
            elseif gold_arc(s, b)
                return RightArc(args(b)...)
            end
        end
        return Shift()
    end
end

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

import Base.==
==(cfg1::ArcEager, cfg2::ArcEager) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A
