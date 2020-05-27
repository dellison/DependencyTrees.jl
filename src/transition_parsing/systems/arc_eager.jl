"""
    ArcEager()

Arc-Eager transition system for dependency parsing.

# Transitions

| Transition  | Definition                                    |
|:----------- |:--------------------------------------------- |
| LeftArc(l)  | (σ\\|s, b\\|β, A) → (σ, b\\|β, A ∪ (b, l, s)) |
| RightArc(l) | (σ\\|s, b\\|β, A) → (σ, b\\|β, A ∪ (b, l, s)) |
| Reduce      | (σ\\|s, β,  A) → (σ, β,   A)                  |
| Shift	      | (σ,  b\\|β, A) → (σ\\|b, β, A)                |

# Preconditions

| Transition  | Condition                        |
|:----------- |:-------------------------------- |
| LeftArc(l)  | ¬[s = 0], ¬∃k∃l'[(k, l', i) ϵ A] |
| RightArc(l) | ¬∃k∃l'[(k, l', j) ϵ A]           |
| Reduce      | ∃k∃l[(k, l, i) ϵ A]              |

# References

[Nivre 2003](http://stp.lingfil.uu.se/~nivre/docs/iwpt03.pdf), [Nivre 2008](https://www.aclweb.org/anthology/J08-4003.pdf).
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

See [Goldberg & Nivre 2012](https://www.aclweb.org/anthology/C12-1059.pdf).
(Also called Arc-Eager-Reduce in [Qi & Manning 2017](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf)).
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

See [Qi & Manning 2017](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf).
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

For details, see [Goldberg & Nivre 2012](https://aclweb.org/anthology/C12-1059).
"""
dynamic_oracle(cfg::ArcEagerConfig, tree, arc=untyped) =
    filter(t -> cost(t, cfg, tree) == 0, possible_transitions(cfg, tree, arc))

# see figure 2 in goldberg & nivre 2012 "a dynamic oracle..."
possible_transitions(cfg::ArcEagerConfig, graph::DependencyTree, arc=untyped) =
    possible_transitions(cfg, arc)

function possible_transitions(cfg::ArcEagerConfig, arc=untyped)
    s, b = last(stack(cfg)), first(buffer(cfg))
    l = i -> arc(token(cfg, i))
    transitions = [LeftArc(l(s)...), RightArc(l(b)...), Reduce(), Shift()]
    return filter(t -> is_possible(t, cfg), transitions)
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
    s = last(stack(cfg))
    return s != 0 && !has_head(token(cfg, s))
end

is_possible(::RightArc, cfg::ArcEagerConfig) =
    !has_head(token(cfg, first(buffer(cfg))))

is_possible(::Reduce, cfg::ArcEagerConfig) =
    has_head(token(cfg, last(stack(cfg))))

is_possible(::Shift, cfg::ArcEagerConfig) = true

==(cfg1::ArcEagerConfig, cfg2::ArcEagerConfig) =
    cfg1.stack == cfg2.stack && cfg1.buffer == cfg2.buffer && cfg1.A == cfg2.A

Base.getindex(cfg::ArcEagerConfig, i) = arc(cfg, i)
