module DependencyTrees

export
    DependencyGraph,
    LabeledDependency,
    TypedDependency,
    UntypedDependency

using LightGraphs

# TODO: move interface into its own file?
abstract type Dependency end

_ni(f, dep) = error("$f not implemented for type $(typeof(t))!")

# Dependency API:
deprel(node::Dependency) = _ni(deprel, node)
form(node::Dependency) = _ni(form, node)
head(node::Dependency) = _ni(head, node)
isroot(node::Dependency) = _ni(isroot, node)
root(node::Dependency) = _ni(root, node)
root(t::Type{Dependency}) = _ni(root, t)
# end of Dependency API

struct DependencyToken{T} <: Dependency
    id::Int
    form::String
    data::T
    head::Int
end

deprel(d::DependencyToken) = d.data
id(d::DependencyToken) = d.id
form(d::DependencyToken) = d.form
head(d::DependencyToken) = d.head

const UntypedDependency = DependencyToken{Nothing}
UntypedDependency(id, form, head) = DependencyToken(id, form, nothing, head)
deprel(d::UntypedDependency) = nothing
isroot(d::UntypedDependency) = (d.form == "ROOT")
root(::Type{UntypedDependency}) = DependencyToken(0, "ROOT", nothing, 0)
root(d::UntypedDependency) = DependencyToken(0, "ROOT", nothing, 0)

const LabeledDependency = DependencyToken{String}
isroot(d::LabeledDependency) = (d.form == "ROOT" && d.data == "ROOT")
postag(d::LabeledDependency) = d.data
deprel(d::LabeledDependency) = d.data
root(::Type{LabeledDependency}) = DependencyToken(0, "ROOT", "ROOT", 0)
root(d::LabeledDependency) = DependencyToken(0, "ROOT", "ROOT", 0)

import Base.==
==(d1::DependencyToken, d2::DependencyToken) =
    d1.id == d2.id && d1.form == d2.form && d1.data == d2.data && d1.head == d2.head

struct DependencyGraph{T<:DependencyToken} <: AbstractGraph{Int}
    graph::SimpleDiGraph
    tokens::Vector{T}
end

function DependencyGraph(t::Type{<:Dependency}, tokens; add_root=true)
    DependencyGraph([t(i, tk...) for (i,tk) in enumerate(tokens)], add_root=add_root)
end

function DependencyGraph(tokens::Vector{<:DependencyToken}; add_root=true)
    add_root && (tokens = [root(eltype(tokens)) ; tokens])
    graph = SimpleDiGraph(length(tokens))
    for dep in tokens
        isroot(dep) && continue
        add_edge!(graph, id(dep), head(dep))
    end
    return DependencyGraph(graph, tokens)
end

==(g1::DependencyGraph, g2::DependencyGraph) = all(g1.tokens .== g2.tokens)
Base.getindex(g::DependencyGraph, i) = g.tokens[i]
Base.length(g::DependencyGraph) = length(g.tokens)

end # module
