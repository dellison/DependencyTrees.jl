"""
    ArcStandard()

Transition system for for Arc-Standard dependency parsing.

See [Nivre 2004](https://www.aclweb.org/anthology/W04-0308.pdf).
"""
struct ArcStandard <: AbstractTransitionSystem end

initconfig(s::ArcStandard, graph::DependencyTree) = ArcStandardConfig(graph)
initconfig(s::ArcStandard, deptype, words) = ArcStandardConfig{deptype}(words)

projective_only(::ArcStandard) = true

transition_space(::ArcStandard, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., Shift()]

struct ArcStandardConfig{T} <: AbstractParserConfiguration{T}
    c::StackBufferConfiguration{T}
end

@stackbufconfig ArcStandardConfig


leftarc(cfg::ArcStandardConfig, args...; kwargs...) =
    ArcStandardConfig(leftarc_popstack2(cfg.c, args...; kwargs...))

rightarc(cfg::ArcStandardConfig, args...; kwargs...) = 
    ArcStandardConfig(rightarc_popstack(cfg.c, args...; kwargs...))

shift(cfg::ArcStandardConfig) = ArcStandardConfig(shift(cfg.c))

isfinal(cfg::ArcStandardConfig) =
    length(stack(cfg)) == 1 && stack(cfg)[1] == 0 && length(buffer(cfg)) == 0

"""
    static_oracle(::ArcStandard, gold_tree)

Static oracle for arc-standard dependency parsing. Closes over gold trees,
mapping parser configurations to optimal transitions.
"""
function static_oracle(cfg::ArcStandardConfig, gold_tree::DependencyTree, transition=untyped)
    args(i) = transition(gold_tree[i])
    s = stack(cfg)
    if length(s) >= 2
        s1, s0 = s[end-1], s[end]
        if has_arc(gold_tree, s0, s1)
            return LeftArc(args(s1)...)
        elseif has_arc(gold_tree, s1, s0)
            if !any(k -> (k in s || k in buffer(cfg)), dependents(gold_tree, s0))
                return RightArc(args(s0)...)
            end
        end
    end
    return Shift()
end

function possible_transitions(cfg::ArcStandardConfig, gold_tree::DependencyTree, transition=untyped)
    ops = TransitionOperator[]
    if length(stack(cfg)) >= 2
        # TODO LeftArc
        # TODO RightArc
    end
    if length(buffer(cfg)) > 0
        push!(ops, Shift())
    end
    return ops
end

==(cfg1::ArcStandardConfig, cfg2::ArcStandardConfig) = cfg1.c == cfg2.c
