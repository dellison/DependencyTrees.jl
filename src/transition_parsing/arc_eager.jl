"""
    ArcEager()

Arc-Eager transition system for dependency parsing.

See [Nivre 2003](http://stp.lingfil.uu.se/~nivre/docs/iwpt03.pdf),
[Nivre 2008](https://www.aclweb.org/anthology/J08-4003.pdf).
"""
struct ArcEager <: AbstractTransitionSystem end

initconfig(::ArcEager, graph::DependencyTree) = ArcEagerConfig(graph)
initconfig(::ArcEager, deptype, words) = ArcEagerConfig{deptype}(words)

transition_space(::ArcEager, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), Reduce(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., Reduce(), Shift()]

projective_only(::ArcEager) = true

struct ArcEagerConfig{T} <: AbstractParserConfiguration{T}
    c::StackBufferConfiguration{T}
end

@stackbufconfig ArcEagerConfig


leftarc(cfg::ArcEagerConfig, args...; kwargs...) =
    ArcEagerConfig(leftarc_popstack(cfg.c, args...; kwargs...))

rightarc(cfg::ArcEagerConfig, args...; kwargs...) =
    ArcEagerConfig(rightarc_shift(cfg.c, args...; kwargs...))

reduce(cfg::ArcEagerConfig) = ArcEagerConfig(reduce(cfg.c))

shift(cfg::ArcEagerConfig) = ArcEagerConfig(shift(cfg.c))

isfinal(cfg::ArcEagerConfig) = all(a -> head(a) >= 0, cfg.c.A)
hashead(cfg::ArcEagerConfig, k) = head(token(cfg, k)) != -1

"""
    static_oracle(::ArcEagerConfig, tree)

Static oracle for arc-eager dependency parsing. Closes over gold trees,
mapping parser configurations to optimal transitions.

See [Goldberg & Nivre 2012](https://www.aclweb.org/anthology/C12-1059.pdf).
(Also called Arc-Eager-Reduce in [Qi & Manning 2017](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf)).
"""
function static_oracle(::ArcEager, tree::DependencyTree, transition=untyped)
    args(i) = transition(tree[i])
    gold_arc(a, b) = has_arc(tree, a, b)

    function (cfg::ArcEagerConfig)
        if length(stack(cfg)) >= 1 && length(buffer(cfg)) >= 1
            s, b = last(stack(cfg)), first(buffer(cfg))
            if gold_arc(b, s)
                return LeftArc(args(s)...)
            elseif gold_arc(s, b)
                return RightArc(args(b)...)
            elseif all(k -> k > 0 && hashead(cfg, k), [s ; dependents(tree, s)])
                return Reduce()
            end
        end
        return Shift()
    end
end

"""
    static_oracle_shift(::ArcEager, graph)

Static oracle for arc-standard dependency parsing. Closes over gold
trees, mapping parser configurations to optimal transitions.  Similar
to the "regular" static oracle, but always Shift when ambiguity is
present.

See [Qi & Manning 2017](https://nlp.stanford.edu/pubs/qi2017arcswift.pdf).
"""
function static_oracle_shift(::ArcEager, graph::DependencyTree, transition=untyped)
    args(i) = transition(graph[i])
    gold_arc(a, b)= has_arc(graph, a, b)

    function (cfg::ArcEagerConfig)
        # (σ, s), (b, β) = σs(cfg), bβ(cfg)
        (σ, s), (b, β) = popstack(cfg), shiftbuffer(cfg)
        if gold_arc(b, s)
            return LeftArc(args(s)...)
        elseif gold_arc(s, b)
            return RightArc(args(b)...)
        end
        must_reduce = !any(k -> gold_arc(k, b) || gold_arc(b, k), cfg.c.stack) ||
            all(k -> k == 0 || hashead(cfg, k), cfg.c.stack)
        has_right_children = any(k -> gold_arc(s, k), cfg.c.buffer)
        if ! must_reduce || s > 0 && !hashead(cfg, s) || has_right_children
            return Shift()
        else
            return Reduce()
        end
    end
end


# see figure 2 in goldberg & nivre 2012 "a dynamic oracle..."
function possible_transitions(cfg::ArcEagerConfig, graph::DependencyTree, transition=untyped)
    ops = TransitionOperator[]
    stacksize, bufsize = length(stack(cfg)), length(buffer(cfg))
    if stacksize >= 1
        σ, s = popstack(cfg)
        if bufsize >= 1
            if !iszero(s)
                h = head(token(cfg, s))
                if !any(k -> id(k) == h, cfg.c.A)
                    push!(ops, LeftArc(transition(graph[s])...))
                end
            end
            b = first(buffer(cfg))
            push!(ops, RightArc(transition(graph[b])...))
        end
        if !iszero(s)
            h = head(token(cfg, s))
            if any(k -> id(k) == h, tokens(cfg))
                push!(ops, Reduce())
            end
        end
    end
    if bufsize > 1
        push!(ops, Shift())
    end
    return ops
end

function possible_transitions(cfg::ArcEagerConfig, transition=untyped)
    ops = TransitionOperator[]
    stacksize, bufsize = length(stack(cfg)), length(buffer(cfg))
    if stacksize >= 1
        # σ, s = σs(cfg)
        σ, s = popstack(cfg)
        if bufsize >= 1
            if !iszero(s)
                h = head(cfg.A[s])
                if !any(k -> id(k) == h, cfg.A)
                    push!(ops, LeftArc(transition(graph[s])...))
                end
            end
            b = first(buffer(cfg))
            push!(ops, RightArc(transition(graph[b])...))
        end
        if !iszero(s)
            h = head(cfg.A[s])
            if any(k -> id(k) == h, tokens(cfg))
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


==(cfg1::ArcEagerConfig, cfg2::ArcEagerConfig) = cfg1.c == cfg2.c

Base.getindex(cfg::ArcEagerConfig, i) = arc(cfg, i)

Base.show(io::IO, c::ArcEagerConfig) =
    print(io, "ArcEagerConfig($(stack(c)),$(buffer(c)))\n$(join([join([id(t),form(t),head(t)],'\t') for t in tokens(c)],'\n'))")
