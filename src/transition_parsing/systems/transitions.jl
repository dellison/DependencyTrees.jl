"""
    untyped(token)

Create an arc without a dependency label.
"""
untyped(token) = ()

"""
    typed(token)

Create an arc with a labeled dependency relation.
"""
typed(token) = (deprel(token),)

abstract type TransitionOperator end
args(r::TransitionOperator) = ()
kwargs(r::TransitionOperator) = NamedTuple()

import Base.==
==(op1::TransitionOperator, op2::TransitionOperator) =
    typeof(op1) == typeof(op2) && args(op1) == args(op2) && kwargs(op1) == kwargs(op2)


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
