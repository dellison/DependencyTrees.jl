# transition arguments
untyped(dep) = ()
typed(dep) = (deprel(dep),)

"""
    TransitionOperator

An abstract type for representing a transition operation for
dependency parsing. TransitionOperators can act as functions (with or
without arguments) on parser configurations, but can also be easily
used as labels for a classifier.
"""
abstract type TransitionOperator end
args(r::TransitionOperator) = ()
kwargs(r::TransitionOperator) = ()

import Base.==
==(op1::TransitionOperator, op2::TransitionOperator) =
    typeof(op1) == typeof(op2) && args(op1) == args(op2) && kwargs(op1) == kwargs(op2)


struct NoArc <: TransitionOperator end
(::NoArc)(cfg) = noarc(cfg)

struct Reduce <: TransitionOperator end
(::Reduce)(cfg) = reduce(cfg)

struct Shift  <: TransitionOperator end
(::Shift)(cfg) = shift(cfg)


struct LeftArc{A<:Tuple,K} <: TransitionOperator
    args::A
    kwargs::K
end

LeftArc(args...; kwargs...) = LeftArc(args, kwargs)

(op::LeftArc)(cfg::AbstractParserConfiguration) = leftarc(cfg, op.args...; op.kwargs...)

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

(op::RightArc)(cfg::AbstractParserConfiguration) = rightarc(cfg, op.args...; op.kwargs...)

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
