"""
    TransitionParserConfiguration

Parser state representation for transition-based dependency parsing.
"""
abstract type TransitionParserConfiguration{T<:Dependency} end

"""
    ArcStandardConfig{T<:Dependency}(words)

Parser configuration for arc-standard transition-based dependency
parsing.
"""
struct ArcStandardConfig{T} <: TransitionParserConfiguration{T}
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
    relations = state.relations
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
    relations = state.relations
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
    length(state.stack) == 1 && state.stack[1] == 0 && length(state.word_buffer) == 0
