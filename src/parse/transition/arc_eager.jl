"""
    ArcEagerConfig{T<:Dependency}(words)

Parser configuration for arc-eager transition-based dependency
parsing.
"""
struct ArcEagerConfig{T} <: TransitionParserConfiguration{T}
    stack::Vector{Int}
    word_buffer::Vector{Int}
    relations::Vector{T}
end

function ArcEagerConfig{T}(words) where T
    stack = [0]
    word_buffer = collect(1:length(words))
    relations = [unk(T, id, w) for (id,w) in enumerate(words)]
    ArcEagerConfig{T}(stack, word_buffer, relations)
end

function leftarc(state::ArcEagerConfig, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    head, dependent = state.word_buffer[1], state.stack[end]
    relations = copy(state.relations)
    if dependent > 0
        relations[dependent] = dep(relations[dependent], head=head, args...; kwargs...)
    end
    ArcEagerConfig(state.stack[1:end-1], state.word_buffer, relations)
end

function rightarc(state::ArcEagerConfig, args...; kwargs...)
    # Assert a head-dependent relation between the word on the top of
    # the stack and the word at front of the input buffer; shift the
    # word at the front of the input buffer to the stack.
    head, dependent = state.stack[end], state.word_buffer[1]
    relations = copy(state.relations)
    relations[dependent] = dep(relations[dependent], head=head, args...; kwargs...)
    buf = state.word_buffer
    ArcEagerConfig([state.stack ; buf[1]], buf[2:end], relations)
end

function shift(state::ArcEagerConfig)
    # Remove the word from the front of the input buffer and push it
    # onto the stack.
    buf = state.word_buffer
    ArcEagerConfig([state.stack ; buf[1]], buf[2:end], state.relations)
end

function Base.reduce(state::ArcEagerConfig)
    # Pop the stack.
    ArcEagerConfig(state.stack[1:end-1], state.word_buffer, state.relations)
end

isfinal(state::ArcEagerConfig) =
    all(r -> head(r) >= 0, state.relations)

"""
    static_oracle(::ArcEagerConfig, graph)

Return an oracle function which predicts the best possible transition
from a parser configuration. See 
"""
function static_oracle(::Type{ArcEagerConfig}, graph::DependencyGraph)
    T = eltype(graph)
    g = depargs(T)
    arc(i) = g(graph[i])
    function (cfg::ArcEagerConfig)
        if length(cfg.stack) >= 1 && length(cfg.word_buffer) >= 1
            s, b = cfg.stack[end], cfg.word_buffer[1]
            if head(graph, s) == b # (s <-- b)
                return LeftArc(arc(s)...)
            elseif head(graph, b) == s # (s --> b)
                return RightArc(arc(b)...)
            elseif all(w -> w != 0 && head(cfg.relations[w]) != -1, [s ; dependents(graph, s)])
                return Reduce()
            end
        end
        # return shift(cfg)
        return Shift()
    end
end

import Base.==
==(cfg1::ArcEagerConfig, cfg2::ArcEagerConfig) =
    cfg1.stack == cfg2.stack && cfg1.word_buffer == cfg2.word_buffer && cfg1.relations == cfg2.relations
