# "parametrizing" transition operaterators
untyped(dep) = ()
typed(dep) = (deprel(dep),)

"""
    TransitionOperator

An abstract type for representing a transition operation for
dependency parsing. TransitionOperators can act as functions (with or
without arguments) on parser configurations, but can also be easily
used as labels in a classifier.
"""
abstract type TransitionOperator end
args(r::TransitionOperator) = ()
kwargs(r::TransitionOperator) = ()

import Base.==
==(op1::TransitionOperator, op2::TransitionOperator) =
    typeof(op1) == typeof(op2) && args(op1) == args(op2) && kwargs(op1) == kwargs(op2)


struct NoArc <: TransitionOperator end
(::NoArc)(config) = noarc(config)

struct Reduce <: TransitionOperator end
(::Reduce)(config) = reduce(config)

struct Shift  <: TransitionOperator end
(::Shift)(config) = shift(config)

struct LeftArc{A<:Tuple,K} <: TransitionOperator
    args::A
    kwargs::K
end

function LeftArc(args...; kwargs...)
    A, K = typeof(args), typeof(kwargs)
    LeftArc{A,K}(args, kwargs)
end
function LeftArc{A,K}(args...; kwargs...) where {A,K}
    LeftArc{A,K}(args, kwargs)
end

(op::LeftArc)(cfg::ParserState) = leftarc(cfg, op.args...; op.kwargs...)

args(op::LeftArc) = op.args
kwargs(op::LeftArc) = op.kwargs

function Base.show(io::IO, op::LeftArc)
    as = join(args(op), ", ")
    kwas = join(["$a=$v" for (a, v) in kwargs(op)], ", ")
    if length(kwas) > 0
        print(io, "LeftArc($as; $kwas)")
    else
        print(io, "LeftArc($as)")
    end
end


struct RightArc{A<:Tuple,K} <: TransitionOperator
    args::A
    kwargs::K
end
    
RightArc(args...; kwargs...) = RightArc(args, kwargs)

(op::RightArc)(cfg::ParserState) = rightarc(cfg, op.args...; op.kwargs...)

args(op::RightArc) = op.args
kwargs(op::RightArc) = op.kwargs

function Base.show(io::IO, op::RightArc)
    as = join(args(op), ", ")
    kwas = join(["$a=$v" for (a, v) in kwargs(op)], ", ")
    if length(kwas) > 0
        print(io, "RightArc($as; $kwas)")
    else
        print(io, "RightArc($as)")
    end
end
