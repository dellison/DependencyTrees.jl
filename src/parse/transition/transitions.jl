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
    args(op1) == args(op2) && kwargs(op1) == kwargs(op2)

"""
    Reduce()

A Reduce transition operation.
"""
struct Reduce <: TransitionOperator end

(::Reduce)(config) = reduce(config)

"""
    Shift()

A Shift transition operation.
"""
struct Shift  <: TransitionOperator end

(::Shift)(config) = shift(config)

"""
    LeftArc(args...; kw...)

A LeftArc transition operation, optionally parameterized.
"""
struct LeftArc <: TransitionOperator
    args::Tuple
    kwargs
end

LeftArc() = LeftArc(())
LeftArc(args...; kwargs...) = LeftArc(args, kwargs)

(op::LeftArc)(cfg::TransitionParserConfiguration) =
    leftarc(cfg, op.args...; op.kwargs...)

args(op::LeftArc) = op.args
kwargs(op::LeftArc) = op.kwargs


"""
    RightArc(args...; kwargs...)

A RightArc transition operation, optionally parameterized.
"""
struct RightArc <: TransitionOperator
    args::Tuple
    kwargs
end
    
RightArc() = RightArc(())
RightArc(args...; kwargs...) = RightArc(args, kwargs)

(op::RightArc)(cfg::TransitionParserConfiguration) =
    rightarc(cfg, op.args...; op.kwargs...)

args(op::RightArc) = op.args
kwargs(op::RightArc) = op.kwargs
