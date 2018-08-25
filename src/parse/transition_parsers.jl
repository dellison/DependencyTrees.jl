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

function leftarc(state::ArcStandardConfig, args...)
    # assert a head-dependent relation between the word at the top of
    # the stack and the word directly beneath it; remove the lower
    # word from the stack
    @assert length(state.stack) >= 2
    head = state.stack[end]
    dependent = state.stack[end-1]
    stack = [state.stack[1:end-2] ; [head]]
    relations = state.relations
    relations[dependent] = dep(relations[dependent], args...; head=head)
    ArcStandardConfig(stack, state.word_buffer, relations)
end

function rightarc(state::ArcStandardConfig, args...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    @assert length(state.stack) >= 2
    dependent = state.stack[end]
    head = state.stack[end-1]
    stack = [state.stack[1:end-2] ; [head]]
    relations = state.relations
    relations[dependent] = dep(relations[dependent], args...; head=head)
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

# function parse(t::Type{<:Dependency}, words, oracle)
#     state = ArcStandardConfig()
#     while !isfinal(state)
#         f = oracle(state)
#         state = f(state)
#     end
#     return state
# end
