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
        ks = kwargs.data
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
        ks = kwargs.data
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

# deptype(::Type{<:AbstractParserConfiguration{D}}) where D = D
# deptype(c::AbstractParserConfiguration) = deptype(typeof(c))

# for f in (:leftdeps, :rightdeps, :leftmostdep, :rightmostdep)
#     @eval $f(cfg::AbstractParserConfiguration, args...) = $f(tokens(cfg), args...)
# end

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
        a_index == 0 ? root(deptype(cfg)) : token(cfg, a_index)
    else
        # noval(deptype(cfg))
        Token()
    end
end

"""
    buffertoken(cfg, i)

Return the token at buffer index `i` (starting at 1).
"""
buffertoken(cfg, i) =
    # 1 <= i <= bufferlength(cfg) ? token(cfg, buffer(cfg)[i]) : noval(deptype(cfg))
    1 <= i <= bufferlength(cfg) ? token(cfg, buffer(cfg)[i]) : Token()
    

struct StackBufferCfg
    stack::Vector{Int}
    buffer::Vector{Int}
    A::Vector{Token}
end

function StackBufferCfg(words)
    σ = [0]
    β = collect(1:length(words))
    # A = [(T, id, w) for (id,w) in enumerate(words)]
    A = Token.(words)
    return StackBufferCfg(σ, β, A)
end

function StackBufferCfg(gold::DependencyTree)
    σ = [0]
    β = collect(1:length(gold))
    # A = [dep(word, head=-1) for word in gold]
    A = [Token(t; head=-1) for t in gold]
    StackBufferCfg(σ, β, A)
end

# StackBufferCfg(gold::DependencyTree) =
#     StackBufferCfg(gold)

deptype(cfg::StackBufferCfg) = eltype(cfg.A)

stacklength(cfg) = length(cfg.stack)
bufferlength(cfg) = length(cfg.stack)

# token(cfg::StackBufferCfg, i) = iszero(i) ? root(deptype(cfg)) :
#                                 i == -1   ? noval(deptype(cfg)) :
#                                 cfg.A[i]
token(cfg::StackBufferCfg, i) = iszero(i) ? ROOT :
                                i == -1   ? Token(nothing) :
                                cfg.A[i]

tokens(cfg::StackBufferCfg) = cfg.A

tokens(cfg::StackBufferCfg, is) =
    [token(cfg, i) for i in is if 0 <= i <= length(cfg.A)]

function popstack(cfg, n=1)
    sh = [s for s in cfg.stack[end-n+1:end]]
    st = length(cfg.stack) >= n ?
        [s for s in cfg.stack[1:end-n]] :
        Int[]
    return (st, sh...)
end

function shiftbuffer(cfg, n=1)
    @assert length(cfg.buffer) >= n "can't shift $n from buffer $(cfg.buffer)"
    bh = [b for b in cfg.buffer[1:n]]
    be = length(cfg.buffer) > n ? 
        [b for b in cfg.buffer[n+1:end]] :
        Int[]
    return (bh..., be)
end

macro stackbufconfig(T, f=:c)
    @eval begin
        $T(words::AbstractVector) = $T(StackBufferCfg(words))
        $T(gold::DependencyTree) = $T(StackBufferCfg(gold))

        # $T{T}(words::AbstractVector) where T =
        #     $T{T}(StackBufferCfg{T}(words))

        # $T{T}(gold::DependencyTree) where T =
        #     $T{T}(StackBufferCfg{T}(gold))

        # $T(gold::DependencyTree) = $T{eltype(gold)}(gold)

        stack(cfg::$T)  = cfg.$f.stack
        buffer(cfg::$T) = cfg.$f.buffer

        stacklength(cfg::$T) = length(cfg.$f.stack)
        bufferlength(cfg::$T) = length(cfg.$f.buffer)

        popstack(cfg::$T, args...)    = popstack(cfg.$f, args...)
        shiftbuffer(cfg::$T, args...) = shiftbuffer(cfg.$f, args...)

        token(cfg::$T, args...)  = token(cfg.$f, args...)
        tokens(cfg::$T, args...) = tokens(cfg.$f, args...)

        DependencyTree(cfg::$T, args...) = DependencyTree(cfg.$f.A, check=false)

        function Base.show(io::IO, cfg::$T)
            println(io, "$(typeof(cfg))($(stack(cfg)),$(buffer(cfg)))")
            for (i, t) in enumerate(tokens(cfg))
                println(join((i, t.form, t.head), "\t"))
            end
        end
    end
end

# LeftArc in ArcStandard
function leftarc_reduce2(cfg, args...; kwargs...)
    # assert a head-dependent relation between the word at the top of
    # the stack and the word directly beneath it; remove the lower
    # word from the stack
    @assert length(cfg.stack) >= 2
    σ, s1, s0 = cfg.stack[1:end-2], cfg.stack[end-1], cfg.stack[end]
    A = copy(cfg.A)
    # A[s1] = dep(A[s1], args...; head=s0, kwargs...)
    A[s1] = Token(A[s1]; head=s0, kwargs...)
    StackBufferCfg([σ ; s0], cfg.buffer, A)
end


# LeftArc in ArcEager
# LeftArc in ArcHybrid
function leftarc_reduce(cfg, args...; kwargs...)
    # Assert a head-dependent relation between the word at the front
    # of the input buffer and the word at the top of the stack; pop
    # the stack.
    s, b, A = cfg.stack[end], cfg.buffer[1], copy(cfg.A)
    if s > 0
        # A[s] = dep(A[s], args...; head=b, kwargs...)
        A[s] = Token(A[s]; head=b, kwargs...)
    end
    StackBufferCfg(cfg.stack[1:end-1], cfg.buffer, A)
end

# RightArc in ArcHybrid
# RightArc in ArcStandard
function rightarc_reduce(cfg, args...; kwargs...)
    # assert a head-dependent relation btwn the 2nd word on the stack
    # and the word on top; remove the word at the top of the stack
    # σ, s1, s0 = σs1s0(cfg)
    σ, s1, s0 = popstack(cfg, 2)
    A = copy(cfg.A)
    if s0 > 0
        # A[s0] = dep(A[s0], args...; head=s1, kwargs...)
        A[s0] = Token(A[s0]; head=s1, kwargs...)
    end
    StackBufferCfg([σ ; s1], cfg.buffer, A)
end

# RightArc in ArcEager
function rightarc_shift(cfg, args...; kwargs...)
    # Assert a head-dependent relation between the word on the top of
    # the σ and the word at front of the input buffer; shift the
    # word at the front of the input buffer to the stack.
    (σ, s), (b, β), A = popstack(cfg), shiftbuffer(cfg), copy(cfg.A)
    # A[b] = dep(A[b], args...; head=s, kwargs...)
    A[b] = Token(A[b]; head=s, kwargs...)
    StackBufferCfg([cfg.stack ; b], β, A)
end

# Reduce in ArcEager
function Base.reduce(cfg)
    # Pop the stack.
    StackBufferCfg(cfg.stack[1:end-1], cfg.buffer, cfg.A)
end

# Shift in ArcEager
# Shift in ArcHybrid
# Shift in ArcStandard
function shift(cfg::StackBufferCfg)
    # Remove the word from the front of the input buffer and push it
    # onto the stack.
    b, β = shiftbuffer(cfg)
    StackBufferCfg([cfg.stack ; b], β, cfg.A)
end

==(cfg1::StackBufferCfg, cfg2::StackBufferCfg) =
    cfg1.stack == cfg2.stack && cfg1.buffer == cfg2.buffer && cfg1.A == cfg2.A
             
