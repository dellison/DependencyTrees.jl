"""
    DependencyGraph

todo
"""
struct DependencyGraph{W} <: AbstractMatrix{W}
    arcs::Matrix{W}
end

function DependencyGraph(tree::DependencyTree)
    n = length(tree.tokens)
    graph = DependencyGraph(zeros(n, n))
    for (i, token) in enumerate(tree.tokens)
        setarc!(graph, token.head, i, 1.0)
    end
    return graph
end

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

getarc(G::DependencyGraph, head, dep) = getindex(G, head, dep)

getarc(G::AbstractMatrix, a...) = getarc(DependencyGraph(G), a...)

function setarc!(graph::DependencyGraph, head::Number, i, x)
    if iszero(head)
        head = i
    end
    graph.arcs[head, i] = x
    return graph
end
function setarc!(graph::DependencyGraph, head, i, x)
    graph.arcs[head, i] = x
    return graph
end




