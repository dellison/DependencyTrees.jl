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
initconfig(::ArcEager, deptype, words) =
    ArcEagerConfig{deptype}(words)

transition_space(::ArcEager, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), Reduce(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., Reduce(), Shift()]

projective_only(::ArcEager) = true

struct ArcEagerConfig{T} <: AbstractParserConfiguration{T}
    c::StackBufferConfiguration{T}
end

@stackbufconfig ArcEagerConfig


leftarc(cfg::ArcEagerConfig, args...; kwargs...) =
    ArcEagerConfig(leftarc_reduce(cfg.c, args...; kwargs...))

rightarc(cfg::ArcEagerConfig, args...; kwargs...) =
    ArcEagerConfig(rightarc_shift(cfg.c, args...; kwargs...))

reduce(cfg::ArcEagerConfig) = ArcEagerConfig(reduce(cfg.c))

shift(cfg::ArcEagerConfig) = ArcEagerConfig(shift(cfg.c))

isfinal(cfg::ArcEagerConfig) = all(a -> head(a) >= 0, cfg.c.A)
hashead(cfg::ArcEagerConfig, k) = head(token(cfg, k)) != -1

"""
    static_oracle(cfg, tree, transition)

Default static oracle function for arc-eager dependency parsing.

See [Goldberg & Nivre 2012](https://www.aclweb.org/anthology/C12-1059.pdf).
(Also called Arc-Eager-Reduce in [Qi & Manning 2017](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf)).
"""
function static_oracle(cfg::ArcEagerConfig, gold_tree, arc)
    l = i -> arc(token(gold_tree, i))
    gold_arc = (a, b) -> has_arc(gold_tree, a, b)
    if stacklength(cfg) >= 1
        s = last(stack(cfg))
        if bufferlength(cfg) >= 1
            b = first(buffer(cfg))
            if gold_arc(b, s)
                return LeftArc(l(s)...)
            elseif gold_arc(s, b)
                return RightArc(l(b)...)
            end
        end
        if all(k -> k > 0 && hashead(cfg, k), [s ; dependents(gold_tree, s)])
            return Reduce()
        end
    end
    return Shift()
end

"""
    static_oracle_prefer_shift(cfg, gold_tree, arc=untyped)

Static oracle for arc-eager dependency parsing. Similar to the
"regular" static oracle, but always Shift when ambiguity is present.

See [Qi & Manning 2017](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf).
"""
function static_oracle_prefer_shift(cfg::ArcEagerConfig, gold_tree, arc=untyped)
    l = i -> arc(token(gold_tree, i))
    gold_arc = (a, b) -> has_arc(gold_tree, a, b)
    (σ, s), (b, β) = popstack(cfg), shiftbuffer(cfg)
    if gold_arc(b, s)
        return LeftArc(l(s)...)
    elseif gold_arc(s, b)
        return RightArc(l(b)...)
    end
    must_reduce = false
    for k in stack(cfg)
        if gold_arc(k, b) || gold_arc(b, k)
            must_reduce = true
            break
        elseif head(token(cfg, k)) < 0
            break
        end
    end
    has_right_children = any(k -> s in rightdeps(gold_tree, k), buffer(cfg))
    if !must_reduce || s > 0 && !hashead(cfg, s) || has_right_children
        return Shift()
    else
        return Reduce()
    end
end

"""
    dynamic_oracle(t, cfg::ArgEagerConfig, tree)

Dynamic oracle function for arc-eager parsing.

For details, see [Goldberg & Nivre 2012](https://aclweb.org/anthology/C12-1059).
"""
dynamic_oracle(t, cfg::ArcEagerConfig, tree) = cost(t, cfg, tree) == 0

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
    if has_dependency(gold, s, b)
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
    return s != 0 && !hashead(token(cfg, s))
end

is_possible(::RightArc, cfg::ArcEagerConfig) =
    !hashead(token(cfg, first(buffer(cfg))))

is_possible(::Reduce, cfg::ArcEagerConfig) =
    hashead(token(cfg, last(stack(cfg))))

is_possible(::Shift, cfg::ArcEagerConfig) = true

==(cfg1::ArcEagerConfig, cfg2::ArcEagerConfig) = cfg1.c == cfg2.c

Base.getindex(cfg::ArcEagerConfig, i) = arc(cfg, i)
