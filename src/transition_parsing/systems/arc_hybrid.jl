"""
    ArcHybrid()

Arc-Hybrid system for transition dependency parsing.

Described in [Kuhlmann et al, 2011](https://www.aclweb.org/anthology/P11-1068.pdf),
[Goldberg & Nivre, 2013](https://aclweb.org/anthology/Q13-1033.pdf).
"""
struct ArcHybrid <: AbstractTransitionSystem end

initconfig(::ArcHybrid, graph::DependencyTree) = ArcHybridConfig(graph)
initconfig(::ArcHybrid, words) = ArcHybridConfig(words)

projective_only(::ArcHybrid) = true

transition_space(::ArcHybrid, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., Shift()]

struct ArcHybridConfig <: AbstractParserConfiguration
    stack::Vector{Int}
    buffer::Vector{Int}
    A::Vector{Token}
end

ArcHybridConfig(sentence) = stack_buffer_config(ArcHybridConfig, sentence)

buffer(cfg::ArcHybridConfig) = cfg.buffer
stack(cfg::ArcHybridConfig)  = cfg.stack
tokens(cfg::ArcHybridConfig) = cfg.A

function Base.show(io::IO, cfg::ArcHybridConfig)
    print(io, "$(typeof(cfg))($(stack(cfg)),$(buffer(cfg)))")
    for (i, t) in enumerate(tokens(cfg))
        print("(",join((i, t.form, t.head), ","), ")")
    end
end

# transition operations: leftarc, rightarc, shift

function apply_transition(f, cfg::ArcHybridConfig, a...; k...)
    σ, β, A = f(cfg.stack, cfg.buffer, cfg.A, a...; k...)
    return ArcHybridConfig(σ, β, A)
end

leftarc(cfg::ArcHybridConfig, args...; kwargs...) =
    apply_transition(leftarc_reduce, cfg, args...; kwargs...)

rightarc(cfg::ArcHybridConfig, args...; kwargs...) =
    apply_transition(rightarc_reduce, cfg, args...; kwargs...)

shift(cfg::ArcHybridConfig) = apply_transition(shift, cfg)

isfinal(cfg::ArcHybridConfig) = all(has_head, tokens(cfg))


"""
    static_oracle(cfg::ArcHybridConfig, tree, arc=untyped)

Static oracle for arc-hybrid dependency parsing.

Return a gold transition (one of LeftArc, RightArc, or Shift)
for parser configuration `cfg`.

TODO paper reference [Kuhlmann et al, 2011](https://www.aclweb.org/anthology/P11-1068.pdf)?
"""
function static_oracle(cfg::ArcHybridConfig, tree, arc=untyped)
    l = i -> arc(token(tree, i))
    if stacklength(cfg) > 0
        σ, s = popstack(cfg)
        if bufferlength(cfg) > 0
            b, β = shiftbuffer(cfg)
            if has_arc(tree, b, s)
                return LeftArc(l(s)...)
            end
        end
        if length(σ) > 0
            s2 = σ[end]
            if has_arc(tree, s2, s) && !any(k -> has_arc(tree, s, k), buffer(cfg))
                return RightArc(l(s)...)
            end
        end
    end
    if bufferlength(cfg) > 0
        return Shift()
    end
end

"""
    dynamic_oracle(cfg::ArgHybridConfig, tree, arc)

Dynamic oracle function for arc-hybrid parsing.

For details, see [Goldberg & Nivre, 2013](https://aclweb.org/anthology/Q13-1033.pdf).
"""
dynamic_oracle(cfg::ArcHybridConfig, tree, arc) =
    filter(t -> cost(t, cfg, tree) == 0, possible_transitions(cfg, tree, arc))

function is_possible(::LeftArc, cfg::ArcHybridConfig)
    s = last(stack(cfg))
    return s != 0 && !has_head(token(cfg, s)) && bufferlength(cfg) > 0
end

is_possible(::RightArc, cfg::ArcHybridConfig) =
    stacklength(cfg) > 1 && !has_head(token(cfg, last(stack(cfg))))

is_possible(::Shift, cfg::ArcHybridConfig) = bufferlength(cfg) >= 1

function cost(t::LeftArc, cfg::ArcHybridConfig, gold)
    # number of arcs (s0, d) and (h, s0) for h ϵ H and d ϵ D
    (σ, s0), (b, β) = popstack(cfg), shiftbuffer(cfg)
    H = length(σ) > 1 ? [σ[end] ; β] : β
    D = buffer(cfg)
    count(d -> has_arc(gold, s0, d), D) + count(h -> has_arc(gold, h, s0), H)
end

function cost(t::RightArc, cfg::ArcHybridConfig, gold)
    # number of arcs (s0,d) and (h,s0) for h, d ϵ B
    s0, n = last(stack(cfg)), 0
    for k in buffer(cfg)
        n += has_arc(gold, s0, k)
        n += has_arc(gold, k, s0)
    end
    return n
end

function cost(t::Shift, cfg::ArcHybridConfig, gold)
    # num of arcs (b, d), (h, b) s.t. h ϵ H, d ϵ D
    b = first(buffer(cfg))
    s, s0 = popstack(cfg)
    D = stack(cfg)
    H = length(D) > 1 ? s : Int[]
    return count(h -> has_arc(gold, h, b), H) + count(d -> has_arc(gold, b, d), D)
end

function possible_transitions(cfg::ArcHybridConfig, arc=untyped)
    s = last(stack(cfg))
    l = arc(token(cfg, s))
    transitions = [LeftArc(l...), RightArc(l...), Shift()]
    return filter(t -> is_possible(t, cfg), transitions)
end

function possible_transitions(cfg::ArcHybridConfig, tree::DependencyTree, arc=untyped)
    s = last(stack(cfg))
    l = arc(token(tree, s))
    transitions = [LeftArc(l...), RightArc(l...), Shift()]
    return filter(t -> is_possible(t, cfg), transitions)
end

==(cfg1::ArcHybridConfig, cfg2::ArcHybridConfig) =
    cfg1.stack == cfg2.stack && cfg1.buffer == cfg2.buffer && cfg1.A == cfg2.A
