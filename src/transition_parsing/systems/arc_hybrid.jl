"""
    ArcHybrid()

Arc-Hybrid system for transition dependency parsing.

Described in [Kuhlmann et al, 2011](https://www.aclweb.org/anthology/P11-1068.pdf),
[Goldberg & Nivre, 2013](https://aclweb.org/anthology/Q13-1033.pdf).
"""
struct ArcHybrid <: AbstractTransitionSystem end

initconfig(::ArcHybrid, graph::DependencyTree) = ArcHybridConfig(graph)
initconfig(::ArcHybrid, deptype, words) = ArcHybridConfig{deptype}(words)

projective_only(::ArcHybrid) = true

transition_space(::ArcHybrid, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., Shift()]

struct ArcHybridConfig{T} <: AbstractParserConfiguration{T}
    c::StackBufferConfiguration{T}
end

@stackbufconfig ArcHybridConfig


# transition operations: leftarc, rightarc, shift

leftarc(cfg::ArcHybridConfig, args...; kwargs...) =
    ArcHybridConfig(leftarc_reduce(cfg.c, args...; kwargs...))

rightarc(cfg::ArcHybridConfig, args...; kwargs...) =
    ArcHybridConfig(rightarc_reduce(cfg.c, args...; kwargs...))

shift(cfg::ArcHybridConfig) = ArcHybridConfig(shift(cfg.c))

isfinal(cfg::ArcHybridConfig) = all(a -> head(a) != -1, tokens(cfg))


"""
    static_oracle(::ArcHybrid, tree)

Static oracle for arc-hybrid dependency parsing. Closes over gold trees,
mapping parser configurations to optimal transitions.
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
    dynamic_oracle(t, cfg::ArgHybridConfig, tree)

Dynamic oracle function for arc-hybrid parsing.

For details, see [Goldberg & Nivre, 2013](https://aclweb.org/anthology/Q13-1033.pdf).
"""
dynamic_oracle(t, cfg::ArcHybridConfig, tree) = cost(t, cfg, tree) == 0


function is_possible(::LeftArc, cfg::ArcHybridConfig)
    s = last(stack(cfg))
    return s != 0 && !hashead(token(cfg, s)) && bufferlength(cfg) > 0
end

is_possible(::RightArc, cfg::ArcHybridConfig) =
    stacklength(cfg) > 1 && !hashead(token(cfg, last(stack(cfg))))

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

possible_transitions(cfg::ArcHybridConfig, tree::DependencyTree, arc=untyped) =
    possible_transitions(cfg, arc)

# function possible_transitions(cfg::ArcHybridConfig, tree::DependencyTree, arc=untyped)
#     ops = TransitionOperator[]
#     S, B = length(stack(cfg)), length(buffer(cfg))
#     if S >= 1
#         s = last(stack(cfg))
#         if !iszero(s) && S > 1
#             push!(ops, RightArc(arc(tree[s])...))
#         end
#         if B >= 1
#             push!(ops, LeftArc(arc(tree[s])...))
#         end
#     end
#     B >= 1 && push!(ops, Shift())
#     return ops
# end


==(cfg1::ArcHybridConfig, cfg2::ArcHybridConfig) = cfg1.c == cfg2.c
