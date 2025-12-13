"""
    ArcEager()

Arc-Eager transition system for dependency parsing.

In Arc-Eager parsing, the parser state consists of:
- A stack `σ`, with `s` at the top: `σ|s`
- a buffer `β`, with `b` at the front: `b|β`
- a list of tokens `A`, each `(h, ℓ, i)`, indicating an arc from `h` to `i` with label `ℓ`

Arcs are drawn between the token at the top the stack, `s`, and and the leftmosttoken on the buffer, `b`.

# Transitions

| Transition  | Definition                                    |
|:----------- |:--------------------------------------------- |
| LeftArc(ℓ)  | `(σ\\|s, b\\|β, A) → (σ, b\\|β, A ∪ (s, ℓ, b))` |
| RightArc(ℓ) | `(σ\\|s, b\\|β, A) → (σ, b\\|β, A ∪ (b, ℓ, s))` |
| Reduce      | `(σ\\|s, β,  A) → (σ, β,   A)`                  |
| Shift	      | `(σ,  b\\|β, A) → (σ\\|b, β, A)`                |

# Preconditions

| Transition  | Condition                          |
|:----------- |:---------------------------------- |
| LeftArc(ℓ)  | `¬[s = 0], ¬∃k∃ℓ'[(k, ℓ', i) ϵ A]` |
| RightArc(ℓ) | `¬∃k∃ℓ'[(k, ℓ', j) ϵ A]`           |
| Reduce      | `∃k∃ℓ[(k, ℓ, i) ϵ A]`              |

# Further Reading

- [Nivre 2003, "An Efficient Algorithm for Projective Dependency Parsing"](https://aclanthology.org/W03-3017/) [nivre-2003-efficient-projective](@cite)
- [Nivre 2008, "Algorithms for Deterministic Incremental Dependency Parsing"](https://aclanthology.org/J08-4003/) [nivre-2008-algorithms-deterministic](@cite).
"""
struct ArcEager <: AbstractTransitionSystem end

initconfig(::ArcEager, graph::DependencyTree) =
    ArcEagerConfig(graph)

transition_space(::ArcEager, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), Reduce(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., Reduce(), Shift()]

projective_only(::ArcEager) = true

struct ArcEagerConfig <: AbstractParserConfiguration
    stack::Vector{Int}
    buffer::Vector{Int}
    A::Vector{Token}
end

ArcEagerConfig(sentence) = stack_buffer_config(ArcEagerConfig, sentence)

buffer(cfg::ArcEagerConfig) = cfg.buffer
stack(cfg::ArcEagerConfig)  = cfg.stack
tokens(cfg::ArcEagerConfig) = cfg.A

function apply_transition(f, cfg::ArcEagerConfig, a...; k...)
    σ, β, A = f(cfg.stack, cfg.buffer, cfg.A, a...; k...)
    return ArcEagerConfig(σ, β, A)
end

leftarc(cfg::ArcEagerConfig, args...; kwargs...) =
    apply_transition(leftarc_reduce, cfg, args...; kwargs...)

rightarc(cfg::ArcEagerConfig, args...; kwargs...) =
    apply_transition(rightarc_shift, cfg, args...; kwargs...)

reduce(cfg::ArcEagerConfig) = apply_transition(reduce, cfg)

shift(cfg::ArcEagerConfig) = apply_transition(shift, cfg)

isfinal(cfg::ArcEagerConfig) = all(has_head, cfg.A)

has_head(cfg::ArcEagerConfig, k) = has_head(token(cfg, k))

"""
    static_oracle(cfg::ArcEagerConfig, gold, arc=untyped)

Default static oracle function for arc-eager dependency parsing.

Descibed in [Goldberg & Nivre 2012](https://aclanthology.org/C12-1059/) [goldberg-nivre-2012-dynamic](@cite).

This is also called "Arc-Eager-Reduce" in [Qi & Manning 2017](https://aclanthology.org/P17-2018/) [qi-manning-2017-arc-swift](@cite).
"""
function static_oracle(cfg::ArcEagerConfig, gold, arc=untyped)
    if stacklength(cfg) >= 1
        (σ, s) = popstack(cfg)
        if bufferlength(cfg) >= 1
            (b, β) = shiftbuffer(cfg)
            has_arc(gold, b, s) && return LeftArc(arc(gold[s])...)
            has_arc(gold, s, b) && return RightArc(arc(gold[b])...)
        end
        if all(k -> k > 0 && has_head(cfg, k), [s ; deps(gold, s)])
            return Reduce()
        end
    end
    return Shift()
end

"""
    static_oracle_prefer_shift(cfg::ArcEagerConfig, tree, arc=untyped)

Static oracle for arc-eager dependency parsing. Similar to the
"regular" static oracle, but always Shift when ambiguity is present.

See [Qi & Manning 2017](https://aclanthology.org/P17-2018/) [qi-manning-2017-arc-swift](@cite).
"""
function static_oracle_prefer_shift(cfg::ArcEagerConfig, tree, arc=untyped)
    l = i -> arc(token(tree, i))
    gold_arc = (a, b) -> has_arc(tree, a, b)
    (σ, s), (b, β) = popstack(cfg), shiftbuffer(cfg)
    gold_arc(b, s) && return LeftArc(l(s)...)
    gold_arc(s, b) && return RightArc(l(b)...)
    must_reduce = false
    for k in stack(cfg)
        if gold_arc(k, b) || gold_arc(b, k)
            must_reduce = true
            break
        elseif has_head(token(cfg, k), -1)
            break
        end
    end
    has_right_children = any(k -> s in rightdeps(tree, k), buffer(cfg))
    if !must_reduce || s > 0 && !has_head(cfg, s) || has_right_children
        return Shift()
    else
        return Reduce()
    end
end

"""
    dynamic_oracle(cfg::ArgEagerConfig, tree, arc=untyped)

Dynamic oracle function for arc-eager parsing.

For details, see [Goldberg & Nivre 2012](https://aclanthology.org/C12-1059/) [goldberg-nivre-2012-dynamic](@cite).
"""
dynamic_oracle(cfg::ArcEagerConfig, tree, arc=untyped) =
    filter(t -> cost(t, cfg, tree) == 0, possible_transitions(cfg, tree, arc))

# see figure 2 in goldberg & nivre 2012 "a dynamic oracle..."
possible_transitions(cfg::ArcEagerConfig, graph::DependencyTree, arc=untyped) =
    possible_transitions(cfg, arc)

function possible_transitions(cfg::ArcEagerConfig, arc=untyped)
    ts = TransitionOperator[]
    if is_possible(LeftArc(), cfg)
        s = last(stack(cfg))
        push!(ts, LeftArc(arc(token(cfg, s))...))
    end
    if is_possible(RightArc(), cfg)
        b = first(buffer(cfg))
        push!(ts, RightArc(arc(token(cfg, b))...))
    end
    is_possible(Reduce(), cfg) && push!(ts, Reduce())
    is_possible(Shift(), cfg) && push!(ts, Shift())
    return ts
end

function cost(t::LeftArc, cfg::ArcEagerConfig, gold)
    # left arc cost: num of arcs (k,l',s), (s,l',k) s.t. k ϵ β
    σ, s = popstack(cfg)
    b, β = shiftbuffer(cfg)
    if has_arc(gold, b, s)
        0
    else
        count(k -> has_arc(gold, k, s) || has_arc(gold, s, k), β)
    end
end

function cost(t::RightArc, cfg::ArcEagerConfig, gold)
    # right arc cost: num of gold arcs (k,l',b), s.t. k ϵ σ or k ϵ β,
    #                 plus num of gold arcs (b,l',k) s.t. k ϵ σ
    σ, s = popstack(cfg)
    b, β = shiftbuffer(cfg)
    if has_arc(gold, s, b)
        0
    else
        count(k -> has_arc(gold, k, b), [σ ; β]) + count(k -> has_arc(gold, b, k), σ)
    end
end

function cost(t::Reduce, cfg::ArcEagerConfig, gold)
    # num of gold arcs (s,l',k) s.t. k ϵ b|β
    σ, s = popstack(cfg)
    count(k -> has_arc(gold, s, k), buffer(cfg))
end

function cost(t::Shift, cfg::ArcEagerConfig, gold)
    # num of gold arcs (k,l',b), (b,l',k) s.t. k ϵ s|σ
    b, β = shiftbuffer(cfg)
    count(k -> has_arc(gold, k, b) || has_arc(gold, b, k), stack(cfg))
end

function is_possible(::LeftArc, cfg::ArcEagerConfig)
    if length(cfg.stack) > 0 && length(cfg.buffer) > 0
        s = last(stack(cfg))
        return s != 0 && !has_head(token(cfg, s))
    end
    return false
end

function is_possible(::RightArc, cfg::ArcEagerConfig)
    return length(cfg.stack) > 0 && length(cfg.buffer) > 0 && 
        !has_head(token(cfg, first(buffer(cfg))))
end

is_possible(::Reduce, cfg::ArcEagerConfig) =
    stacklength(cfg) > 0 && has_head(token(cfg, last(stack(cfg))))

is_possible(::Shift, cfg::ArcEagerConfig) = bufferlength(cfg) > 0

==(cfg1::ArcEagerConfig, cfg2::ArcEagerConfig) =
    cfg1.stack == cfg2.stack && cfg1.buffer == cfg2.buffer && cfg1.A == cfg2.A

Base.getindex(cfg::ArcEagerConfig, i) = token(cfg, i)
