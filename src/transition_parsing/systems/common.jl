abstract type TransitionOperator end

args(r::TransitionOperator) = ()
kwargs(r::TransitionOperator) = NamedTuple()

import Base.==
==(op1::TransitionOperator, op2::TransitionOperator) =
    typeof(op1) == typeof(op2) && args(op1) == args(op2) && kwargs(op1) == kwargs(op2)

is_possible(t, cfg) = false

struct NoArc <: TransitionOperator end
(::NoArc)(cfg) = noarc(cfg)

struct Reduce <: TransitionOperator end
(::Reduce)(cfg) = reduce(cfg)

struct Shift  <: TransitionOperator end
(::Shift)(cfg) = shift(cfg)


struct LeftArc{A<:Tuple,K<:NamedTuple} <: TransitionOperator
    args::A
    kwargs::K

    function LeftArc(args...; kwargs...)
        A = typeof(args)
        ks = values(kwargs)
        K = typeof(ks)
        new{A,K}(args, ks)
    end
end

(op::LeftArc)(cfg) = leftarc(cfg, op.args...; op.kwargs...)

name(::LeftArc) = "LeftArc"
args(op::LeftArc) = op.args
kwargs(op::LeftArc) = op.kwargs

struct RightArc{A<:Tuple,K<:NamedTuple} <: TransitionOperator
    args::A
    kwargs::K

    function RightArc(args...; kwargs...)
        A = typeof(args)
        ks = values(kwargs)
        K = typeof(ks)
        new{A,K}(args, ks)
    end
end

(op::RightArc)(cfg) = rightarc(cfg, op.args...; op.kwargs...)

name(::RightArc) = "RightArc"
args(op::RightArc) = op.args
kwargs(op::RightArc) = op.kwargs

function Base.show(io::IO, op::Union{LeftArc,RightArc})
    as = join(args(op), ", ")
    kwas = join(["$a=$v" for (a, v) in Dict(zip(keys(op.kwargs), values(op.kwargs)))], ", ")
    T = name(op)
    if length(op.kwargs) > 0
        print(io, "$T($as; $kwas)")
    else
        print(io, "$T($as)")
    end
end


abstract type AbstractParserConfiguration end

deptree(cfg::AbstractParserConfiguration) = deptree(tokens(cfg))

"""
    stacktoken(cfg, i)

Return the token at stack index `i` (starting at 1).
"""
function stacktoken(cfg, i=1)
    stk = stack(cfg)
    stklen = length(stk)
    s_index = stacklength(cfg) - i + 1
    if 1 <= s_index <= stacklength(cfg)
        a_index = stk[s_index]
        a_index == 0 ? ROOT : token(cfg, a_index)
    else
        Token()
    end
end

"""
    buffertoken(cfg, i)

Return the token at buffer index `i` (starting at 1).
"""
buffertoken(cfg, i) =
    1 <= i <= bufferlength(cfg) ? token(cfg, buffer(cfg)[i]) : Token()
    

function stack_buffer_config(T, words)
    σ = [0]
    β = collect(1:length(words))
    A = Token.(words)
    return T(σ, β, A)
end

function stack_buffer_config(T, gold::DependencyTree)
    σ = [0]
    β = collect(1:length(gold))
    A = [Token(t; head=-1) for t in gold]
    T(σ, β, A)
end

stacklength(cfg) = length(stack(cfg))
bufferlength(cfg) = length(buffer(cfg))

token(cfg::AbstractParserConfiguration, i) =
    iszero(i) ? ROOT : i == -1   ? Token(nothing) : tokens(cfg)[i]

tokens(cfg::AbstractParserConfiguration, is) =
    [token(cfg, i) for i in is if 0 <= i <= length(tokens(cfg))]

popstack(cfg::AbstractParserConfiguration, n=1) = popstack(stack(cfg), n)

function popstack(stk::Vector, n=1)
    sh = [s for s in stk[end-n+1:end]]
    st = length(stk) >= n ? [s for s in stk[1:end-n]] : Int[]
    return (st, sh...)
end

shiftbuffer(cfg::AbstractParserConfiguration, n=1) = shiftbuffer(buffer(cfg), n)

function shiftbuffer(buf, n=1)
    @assert length(buf) >= n "can't shift $n from buffer $buf"
    bh = [b for b in buf[1:n]]
    be = length(buf) > n ? [b for b in buf[n+1:end]] : Int[]
    return (bh..., be)
end

# LeftArc in ArcStandard
# function leftarc_reduce2(cfg, args...; kwargs...)
function leftarc_reduce2(stack, buffer, A, args...; kwargs...)
    # assert a head-dependent relation between the word at the top of
    # the stack and the word directly beneath it; remove the lower
    # word from the stack
    @assert length(stack) >= 2
    σ, s1, s0 = stack[1:end-2], stack[end-1], stack[end]
    A = copy(A)
    A[s1] = Token(A[s1]; head=s0, kwargs...)
    return [σ ; s0], buffer, A
end


# LeftArc in ArcEager
# LeftArc in ArcHybrid
function leftarc_reduce(stack, buffer, A, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    (σ, s) = popstack(stack)
    A = copy(A)
    if s > 0
        b, β = shiftbuffer(buffer)
        A[s] = Token(A[s]; head=b, kwargs...)
    end
    return σ, buffer, A
end

# RightArc in ArcHybrid
# RightArc in ArcStandard
function rightarc_reduce(stack, buffer, A, args...; kwargs...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    # σ, s1, s0 = σs1s0(cfg)
    σ, s1, s0 = popstack(stack, 2)
    A = copy(A)
    if s0 > 0
        A[s0] = Token(A[s0]; head=s1, kwargs...)
    end
    return [σ ; s1], buffer, A
end

# RightArc in ArcEager
function rightarc_shift(stack, buffer, A, args...; kwargs...)
    # Assert a head-dependent relation between the word on the top of
    # the σ and the word at front of the input buffer; shift the
    # word at the front of the input buffer to the stack.
    (σ, s), (b, β) = popstack(stack), shiftbuffer(buffer)
    A = copy(A)
    A[b] = Token(A[b]; head=s, kwargs...)
    return [stack ; b], β, A
end

# Reduce in ArcEager
function Base.reduce(stack::Vector, buffer::Vector, A::Vector)
    # Pop the stack.
    return stack[1:end-1], buffer, A
end

# Shift in ArcEager
# Shift in ArcHybrid
# Shift in ArcStandard
function shift(stack, buffer, A)
    # Remove the word from the front of the input buffer and push it
    # onto the stack.
    b, β = shiftbuffer(buffer)
    return [stack ; b], β, A
end
