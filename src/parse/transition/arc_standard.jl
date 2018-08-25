"""
    ArcStandardConfig{T<:Dependency}(words)

Parser configuration for arc-standard transition-based dependency
parsing.
"""
struct ArcStandardConfig{T<:Dependency} <: TransitionParserConfiguration{T}
    stack::Vector{Int}
    word_buffer::Vector{Int}
    relations::Vector{T}
end

function ArcStandardConfig{T}(words) where T
    stack = [0]
    word_buffer = collect(1:length(words))
    relations = [unk(T, id, w) for (id,w) in enumerate(words)]
    ArcStandardConfig{T}(stack, word_buffer, relations)
end

# transition operations: leftarc, rightarc, shift

function leftarc(state::ArcStandardConfig, args...; kwargs...)
    # assert a head-dependent relation between the word at the top of
    # the stack and the word directly beneath it; remove the lower
    # word from the stack
    @assert length(state.stack) >= 2
    stack = state.stack
    head, dependent = stack[end], stack[end-1]
    stack = [stack[1:end-2] ; [head]]
    relations = state.relations
    relations[dependent] = dep(relations[dependent], args...; head=head, kwargs...)
    ArcStandardConfig(stack, state.word_buffer, relations)
end

function rightarc(state::ArcStandardConfig, args...; kwargs...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    @assert length(state.stack) >= 2
    dependent, head = state.stack[end], state.stack[end-1]
    stack = [state.stack[1:end-2] ; [head]]
    relations = state.relations
    relations[dependent] = dep(relations[dependent], args...; head=head, kwargs...)
    ArcStandardConfig(stack, state.word_buffer, relations)
end

function shift(state::ArcStandardConfig)
    # remove the word from the front of the input buffer and push it
    # onto the stack
    @assert length(state.word_buffer) >= 1
    word = state.word_buffer[1]
    word_buffer = state.word_buffer[2:end]
    ArcStandardConfig([state.stack ; word], word_buffer, state.relations)
end

isfinal(state::ArcStandardConfig) =
    length(state.stack) == 1 && state.stack[1] == 0 && length(state.word_buffer) == 0

# TODO: should oracle be config -> config or have another return type?
function training_oracle(::Type{ArcStandardConfig}, graph::DependencyGraph)
    T = eltype(graph)
    argsfun = goldargs(T)
    function (config)
        if length(config.stack) >= 2
            second, top = config.stack[end-1], config.stack[end]
            if has_dependency(graph, top, second) # (second <-- top)
                return leftarc(config, argsfun(graph[second])...)
            elseif has_dependency(graph, second, top) # (second --> top)
                if all([!(dp in config.stack || dp in config.word_buffer)
                        for dp in dependents(graph, top)])
                    return rightarc(config, argsfun(graph[top])...)
                end
            end
        end
        return shift(config)
    end
end

import Base.==
==(cfg1::ArcStandardConfig, cfg2::ArcStandardConfig) =
    cfg1.stack == cfg2.stack && cfg1.word_buffer == cfg2.word_buffer && cfg1.relations == cfg2.relations
