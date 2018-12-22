"""
    EasyFirst

Described in [Goldberg & Elhadad, 2010](https://www.aclweb.org/anthology/N/N10/N10-1115.pdf).
"""
struct EasyFirst{T} <: TransitionParserConfiguration{T}
    pending::Vector{Int}
    A::Vector{T}
end

function attach_left(cfg::EasyFirst, i, args...; kwargs...)
    # adds a dependency edge (pi+1, pi) and removes pi+1
end

function attach_right(cfg::EasyFirst, i, args...; kwargs...)
    # adds a dependency edge (pi+1 ,pi) and removes pi
end
