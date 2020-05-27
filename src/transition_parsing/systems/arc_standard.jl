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
initconfig(s::ArcStandard, words) = ArcStandardConfig(words)

projective_only(::ArcStandard) = true

transition_space(::ArcStandard, labels=[]) =
    isempty(labels) ? [LeftArc(), RightArc(), Shift()] :
    [LeftArc.(labels)..., RightArc.(labels)..., Shift()]


struct ArcStandardConfig <: AbstractParserConfiguration
    stack::Vector{Int}
    buffer::Vector{Int}
    A::Vector{Token}
end

ArcStandardConfig(sentence) = stack_buffer_config(ArcStandardConfig, sentence)

buffer(cfg::ArcStandardConfig) = cfg.buffer
stack(cfg::ArcStandardConfig)  = cfg.stack
tokens(cfg::ArcStandardConfig) = cfg.A

function Base.show(io::IO, cfg::ArcStandardConfig)
    print(io, "$(typeof(cfg))($(stack(cfg)),$(buffer(cfg)))")
    for (i, t) in enumerate(tokens(cfg))
        print("(",join((i, t.form, t.head), ","), ")")
    end
end

function apply_transition(f, cfg::ArcStandardConfig, a...; k...)
    σ, β, A = f(cfg.stack, cfg.buffer, cfg.A, a...; k...)
    return ArcStandardConfig(σ, β, A)
end

leftarc(cfg::ArcStandardConfig, args...; kwargs...) =
    apply_transition(leftarc_reduce2, cfg, args...; kwargs...)

rightarc(cfg::ArcStandardConfig, args...; kwargs...) =
    apply_transition(rightarc_reduce, cfg, args...; kwargs...)

shift(cfg::ArcStandardConfig) =
    apply_transition(shift, cfg)

isfinal(cfg::ArcStandardConfig) =
    length(stack(cfg)) == 1 && stack(cfg)[1] == 0 && length(buffer(cfg)) == 0

"""
    static_oracle(cfg, gold_tree)

Static oracle for arc-standard dependency parsing.
"""
function static_oracle(cfg::ArcStandardConfig, gold_tree, arc=untyped)
    l = i -> arc(gold_tree[i])
    s = stack(cfg)
    if length(s) >= 2
        s1, s0 = s[end-1], s[end]
        if has_arc(gold_tree, s0, s1)
            return LeftArc(l(s1)...)
        elseif has_arc(gold_tree, s1, s0)
            if !any(k -> (k in s || k in buffer(cfg)), deps(gold_tree, s0))
                return RightArc(l(s0)...)
            end
        end
    end
    return Shift()
end

function is_possible(::LeftArc, cfg::ArcStandardConfig)
    if stacklength(cfg) >= 2
        s, s1, s0 = popstack(cfg, 2)
        return s1 != 0 && !has_head(token(cfg, s1))
    else
        return false
    end
end

is_possible(::RightArc, cfg::ArcStandardConfig) =
    stacklength(cfg) > 1 && !has_head(token(cfg, last(stack(cfg))))

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

==(cfg1::ArcStandardConfig, cfg2::ArcStandardConfig) =
    cfg1.stack == cfg2.stack && cfg1.buffer == cfg2.buffer && cfg1.A == cfg2.A
