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

# LeftArc(args...; kwargs...) = LeftArc(args, kwargs.data)
# LeftArc(::Tuple{Tuple{}}) = LeftArc()

(op::LeftArc)(cfg::AbstractParserConfiguration) = leftarc(cfg, op.args...; op.kwargs...)

name(::LeftArc) = "LeftArc"
args(op::LeftArc) = op.args
kwargs(op::LeftArc) = op.kwargs

# function Base.show(io::IO, op::LeftArc)
#     as = join(args(op), ", ")
#     # kwas = join(["$a=$v" for (a, v) in kwargs(op)], ", ")
#     kwas = kwargs(op)
#     if length(kwas) > 0
#         print(io, "LeftArc($as; $kwas)")
#     else
#         print(io, "LeftArc($as)")
#     end
# end


struct RightArc{A<:Tuple,K<:NamedTuple} <: TransitionOperator
    args::A
    kwargs::K

    # RightArc(args...; kwargs...) = new(args, kwargs.data)
    function RightArc(args...; kwargs...)
        A = typeof(args)
        ks = kwargs.data
        K = typeof(ks)
        new{A,K}(args, ks)
    end

end
    
# RightArc(args...; kwargs...) = RightArc(args, kwargs.data)
# RightArc(::Tuple{Tuple{}}) = RightArc()

(op::RightArc)(cfg::AbstractParserConfiguration) = rightarc(cfg, op.args...; op.kwargs...)

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
