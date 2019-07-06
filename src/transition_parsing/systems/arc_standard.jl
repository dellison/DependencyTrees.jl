"""
    ArcStandard()

Transition system for for Arc-Standard dependency parsing.

# Transitions

| Transition  | Definition                                         |
|:----------- |:-------------------------------------------------- |
| LeftArc(l)  | (σ\\|s1\\|s0, β, A) → (σ\\|s0, β, A ∪ (s0, l, s1)) |
| RightArc(l) | (σ\\|s, b\\|β, A) → (σ, b\\|β, A ∪ (b, l, s))      |
| Shift	      | (σ,  b\\|β, A) → (σ\\|b, β, A)                     |


# Preconditions

| Transition  | Condition                          |
|:----------- |:---------------------------------- |
| LeftArc(l)  | ¬[s1 = 0], ¬∃k∃l'[(k, l', s1) ϵ A] |
| RightArc(l) | ¬∃k∃l'[(k, l', s0) ϵ A]            |

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
    ArcStandardConfig(leftarc_reduce2(cfg.c, args...; kwargs...))

rightarc(cfg::ArcStandardConfig, args...; kwargs...) = 
    ArcStandardConfig(rightarc_reduce(cfg.c, args...; kwargs...))

shift(cfg::ArcStandardConfig) = ArcStandardConfig(shift(cfg.c))

isfinal(cfg::ArcStandardConfig) =
    length(stack(cfg)) == 1 && stack(cfg)[1] == 0 && length(buffer(cfg)) == 0

"""
    static_oracle(cfg, gold_tree)

Static oracle for arc-standard dependency parsing. Closes over gold trees,
mapping parser configurations to optimal transitions.
"""
function static_oracle(cfg::ArcStandardConfig, gold_tree, arc=untyped)
    l = i -> arc(gold_tree[i])
    s = stack(cfg)
    if length(s) >= 2
        s1, s0 = s[end-1], s[end]
        if has_arc(gold_tree, s0, s1)
            return LeftArc(l(s1)...)
        elseif has_arc(gold_tree, s1, s0)
            if !any(k -> (k in s || k in buffer(cfg)), dependents(gold_tree, s0))
                return RightArc(l(s0)...)
            end
        end
    end
    return Shift()
end

function is_possible(::LeftArc, cfg::ArcStandardConfig)
    if stacklength(cfg) >= 2
        s, s1, s0 = popstack(cfg, 2)
        return s1 != 0 && !hashead(token(cfg, s1))
    else
        return false
    end
end

is_possible(::RightArc, cfg::ArcStandardConfig) =
    stacklength(cfg) > 1 && !hashead(token(cfg, last(stack(cfg))))

is_possible(::Shift, cfg::ArcStandardConfig) = stacklength(cfg) > 0

function possible_transitions(cfg::ArcStandardConfig, arc=untyped)
    l = i -> arc(token(cfg, i))
    if stacklength(cfg) >= 2
        σ, s1, s0 = popstack(cfg, 2)
        transitions = [LeftArc(l(s1)...), RightArc(l(s0)...), Shift()]
        return filter(t -> is_possible(t, cfg), transitions)
    else
        return filter(t -> is_possible(t, cfg), TransitionOperator[Shift()])
    end
end

possible_transitions(cfg::ArcStandardConfig, gold_tree::DependencyTree, arc=untyped) =
    possible_transitions(cfg, arc)

==(cfg1::ArcStandardConfig, cfg2::ArcStandardConfig) = cfg1.c == cfg2.c
