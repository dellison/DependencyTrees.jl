"""
    ArcEager

Transition system for Arc-Eager dependency parsing.

See [Nivre 2003](http://stp.lingfil.uu.se/~nivre/docs/iwpt03.pdf),
[Nivre 2008](https://www.aclweb.org/anthology/J/J08/J08-4003.pdf).
"""
struct ArcEager <: AbstractTransitionSystem end

initconfig(s::ArcEager, graph::DependencyTree) = ArcEagerConfig(graph)
initconfig(s::ArcEager, deptype, words) = ArcEagerConfig{deptype}(words)

projective_only(::ArcEager) = true

struct ArcEagerConfig{T} <: AbstractParserConfiguration{T}
    σ::Vector{Int}
    β::Vector{Int}
    A::Vector{T}
end

function ArcEagerConfig{T}(words) where T
    σ = [0]
    β = collect(1:length(words))
    A = [unk(T, i, word) for (i, word) in enumerate(words)]
    ArcEagerConfig{T}(σ, β, A)
end

function ArcEagerConfig{T}(gold::DependencyTree) where T
    σ = [0]
    β = collect(1:length(gold))
    A = [dep(word, head=-1) for word in gold]
    ArcEagerConfig{T}(σ, β, A)
end
ArcEagerConfig(gold::DependencyTree) = ArcEagerConfig{eltype(gold)}(gold)

arcs(cfg::ArcEagerConfig) = cfg.A
deptype(cfg::ArcEagerConfig) = eltype(cfg.A)

function leftarc(cfg::ArcEagerConfig, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    s, b, A = cfg.σ[end], cfg.β[1], copy(cfg.A)
    if s > 0
        A[s] = dep(A[s], args...; head=b, kwargs...)
    end
    ArcEagerConfig(cfg.σ[1:end-1], cfg.β, A)
end

function rightarc(cfg::ArcEagerConfig, args...; kwargs...)
    # Assert a head-dependent relation between the word on the top of
    # the σ and the word at front of the input buffer; shift the
    # word at the front of the input buffer to the stack.
    (σ, s), (b, β), A = σs(cfg), bβ(cfg), copy(cfg.A)
    A[b] = dep(A[b], args...; head=s, kwargs...)
    ArcEagerConfig([cfg.σ ; b], β, A)
end

function Base.reduce(cfg::ArcEagerConfig)
    # Pop the stack.
    ArcEagerConfig(cfg.σ[1:end-1], cfg.β, cfg.A)
end

function shift(cfg::ArcEagerConfig)
    # Remove the word from the front of the input buffer and push it
    # onto the stack.
    (b, β) = bβ(cfg)
    ArcEagerConfig([cfg.σ ; b], β, cfg.A)
end

isfinal(cfg::ArcEagerConfig) = all(a -> head(a) >= 0, cfg.A)
hashead(cfg::ArcEagerConfig, k) = head(cfg.A[k]) != -1


"""
    static_oracle(::ArcEagerConfig, graph)

Return a static oracle function which maps parser states to gold transition
operations with reference to `graph`.

Described in [Goldberg & Nivre 2012](https://www.aclweb.org/anthology/C/C12/C12-1059.pdf).
Also called Arc-Eager-Reduce in [Qi & Manning 2007](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf).
"""
function static_oracle(::ArcEager, graph::DependencyTree, tr = typed)
    args(i) = tr(graph[i])
    gold_arc(a, b) = has_arc(graph, a, b)

    function (cfg::ArcEagerConfig)
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
function static_oracle_shift(::ArcEager, graph::DependencyTree, tr = typed)
    args(i) = tr(graph[i])
    gold_arc(a, b)= has_arc(graph, a, b)

    function (cfg::ArcEagerConfig)
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


# see figure 2 in goldberg & nivre 2012 "a dynamic oracle..."
function possible_transitions(cfg::ArcEagerConfig, graph::DependencyTree, tr = typed)
    ops = TransitionOperator[]
    stacksize, bufsize = length(cfg.σ), length(cfg.β)
    if stacksize >= 1
        σ, s = σs(cfg)
        if bufsize >= 1
            if !iszero(s)
                h = head(cfg.A[s])
                if !any(k -> id(k) == h, cfg.A)
                    push!(ops, LeftArc(tr(graph[s])...))
                end
            end
            push!(ops, RightArc(tr(graph[cfg.β[1]])...))
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


function cost(t::LeftArc, cfg::ArcEagerConfig, gold)
    # left arc cost: num of arcs (k,l',s), (s,l',k) s.t. k ϵ β
    σ, s = σs(cfg)
    b, β = bβ(cfg)
    if has_dependency(gold, b, s)
        0
    else
        count(k -> has_arc(gold, k, s) || has_arc(gold, s, k), β)
    end
end

function cost(t::RightArc, cfg::ArcEagerConfig, gold)
    # right arc cost: num of gold arcs (k,l',b), s.t. k ϵ σ or k ϵ β,
    #                 plus num of gold arcs (b,l',k) s.t. k ϵ σ
    σ, s = σs(cfg)
    b, β = bβ(cfg)
    if has_dependency(gold, s, b)
        0
    else
        count(k -> has_arc(gold, k, b), [σ ; β]) + count(k -> has_arc(gold, b, k), σ)
    end
end

function cost(t::Reduce, cfg::ArcEagerConfig, gold)
    # num of gold arcs (s,l',k) s.t. k ϵ b|β
    σ, s = σs(cfg)
    count(k -> has_arc(gold, s, k), cfg.β)
end

function cost(t::Shift, cfg::ArcEagerConfig, gold)
    # num of gold arcs (k,l',b), (b,l',k) s.t. k ϵ s|σ
    b, β = bβ(cfg)
    count(k -> has_arc(gold, k, b) || has_arc(gold, b, k), cfg.σ)
end


import Base.==
==(cfg1::ArcEagerConfig, cfg2::ArcEagerConfig) =
    cfg1.σ == cfg2.σ && cfg1.β == cfg2.β && cfg1.A == cfg2.A
