"""
    DependencyGraph

A square matrix of arc weights, reprenting a (set of) dependency parse trees.

Root arc scores are kept along the diagonal.
"""
struct DependencyGraph{W} <: AbstractMatrix{W}
    arcs::Matrix{W}
end

"""
    DependencyGraph(tree::DependencyTree)

Create a dependency graph from `tree`.

Arcs will have a score of `1.0`, and non-arcs `0.0`.

```jldoctest
julia> using DependencyTrees, DependencyTrees.GraphParsing

julia> tree = DependencyTree([(0, "book"), (3, "that"), (1, "flight")])
┌──────── 0 ROOT
└─►┌───── 1 book
   │  ┌─► 2 that
   └─►└── 3 flight

julia> graph = DependencyGraph(tree)
3×3 DependencyGraph{Float64}:
 1.0  0.0  1.0
 0.0  0.0  0.0
 0.0  1.0  0.0

```
"""
function DependencyGraph(tree::DependencyTree)
    n = length(tree.tokens)
    G = DependencyGraph(zeros(n, n))
    for (i, token) in enumerate(tree.tokens)
        setarc!(G, token.head, i, 1.0)
    end
    return G
end

Base.copy(G::DependencyGraph) = DependencyGraph(copy(G.arcs))

function Base.getindex(G::DependencyGraph, i::Int, j::Int)
    if iszero(i)
        getindex(G.arcs, j, j)
    else
        getindex(G.arcs, i, j)
    end
end
Base.getindex(G::DependencyGraph, args...) = getindex(G.arcs, args...)

Base.length(G::DependencyGraph) = length(G.arcs)
Base.size(G::DependencyGraph, a...) = size(G.arcs, a...)

function Base.setindex!(G::DependencyGraph, i::Int, j::Int)
    if iszero(i)
        setindex!(G.arcs, j, j)
    else
        setindex!(G.arcs, i, j)
    end
end
Base.setindex!(G::DependencyGraph, args...) = setindex!(G.arcs, args...)

getarc(G::DependencyGraph, head, dep) = getindex(G, head, dep)

getarc(G::AbstractMatrix, a...) = getarc(DependencyGraph(G), a...)

function setarc!(G::DependencyGraph, head::Number, i, x)
    if iszero(head)
        head = i
    end
    G.arcs[head, i] = x
    return G
end
function setarc!(G::DependencyGraph, head, i, x)
    G.arcs[head, i] = x
    return G
end
