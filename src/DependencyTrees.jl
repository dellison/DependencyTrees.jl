module DependencyTrees

export DependencyGraph

using AbstractTrees
using LightGraphs

abstract type Dependency end

struct DependencyToken{T} <: Dependency
    form::String
    data::T
    head::Int
end

DependencyToken(p::Pair) = DependencyToken(p.first, nothing, p.second)
DependencyToken(t::Tuple{String,Int}) = DependencyToken(t[1], nothing, t[2])
DependencyToken{T}(t::Tuple{String,T,Int}) where T = DependencyToken{T}(t...)
DependencyToken(token, head) = DependencyToken(token, nothing, head)
DependencyToken(token, arc, head) = DependencyToken(token, arc, head)

const UntypedDependency = DependencyToken{Nothing}
isroot(d::UntypedDependency) = (d.form == "ROOT")
root(::Type{UntypedDependency}) = DependencyToken("ROOT", nothing, 0)
root(d::UntypedDependency) = DependencyToken("ROOT", nothing, 0)

const LabeledDependency = DependencyToken{String}
isroot(d::LabeledDependency) = (d.form == "ROOT" && d.data == "ROOT")
root(::Type{LabeledDependency}) = DependencyToken("ROOT", "ROOT", 0)
root(d::LabeledDependency) = DependencyToken("ROOT", "ROOT", 0)


struct DependencyGraph{T<:DependencyToken} <: AbstractGraph{Int}
    graph::SimpleDiGraph
    dependencies::Vector{T}
end

DependencyGraph(sentence; add_root=true) =
    DependencyGraph(DependencyToken{String}, sentence, add_root=add_root)

function DependencyGraph(t::Type{<:Dependency}, sentence; add_root=true)
    deps = [t(token) for token in sentence]
    add_root && (deps = [root(t) ; deps])
    graph = SimpleDiGraph(length(deps))
    for (i, dep) in enumerate(deps)
        add_edge!(graph, i, dep.head)
    end
    DependencyGraph{t}(graph, deps)
end

Base.length(g::DependencyGraph) = length(g.dependencies)

# AbstractTrees.children(

LightGraphs.edges(g::DependencyGraph) = edges(g.graph)
# Base.eltype
LightGraphs.has_edge(g::DependencyGraph, s, d) = has_edge(g.graph, s, d)
LightGraphs.has_vertex(g::DependencyGraph, s, d) = has_vertex(g.graph, s, d)
LightGraphs.inneighbors(g::DependencyGraph, v) = inneighbors(g.graph, v)
LightGraphs.ne(g::DependencyGraph) = ne(g.graph)
LightGraphs.nv(g::DependencyGraph) = nv(g.graph)
LightGraphs.outneighbors(g::DependencyGraph, v) = outneighbors(g.graph, v)
LightGraphs.vertices(g::DependencyGraph) = vertices(g.graph)
LightGraphs.is_directed(::Type{DependencyGraph}) = true
LightGraphs.is_directed(g::DependencyGraph) = true

end # module
