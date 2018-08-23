struct DependencyGraph{T<:Dependency} <: AbstractGraph{Int}
    graph::SimpleDiGraph
    tokens::Vector{T}
    root::Int

    function DependencyGraph(graph, tokens, root)
        g = new{eltype(tokens)}(graph, tokens, root)
        check_depgraph(g)
        return g
    end
end

# ??
function DependencyGraph(t::Type{<:Dependency}, tokens)
    DependencyGraph([t(i, tk...) for (i,tk) in enumerate(tokens)])
end

function DependencyGraph(tokens::Vector{<:Dependency})
    rt = 0
    graph = SimpleDiGraph(length(tokens))
    for dep in tokens
        isroot(dep) && continue
        i, h = id(dep), head(dep)
        iszero(h) && (rt = i)
        add_edge!(graph, h, i) # arrows point from head to dependent
    end
    return DependencyGraph(graph, tokens, rt)
end

function check_depgraph(g::DependencyGraph)
    iszero(g.root) && throw(RootlessGraphError(g))
    count(t -> iszero(head(t)), g.tokens) > 1 && throw(MultipleRootsError(g))
    if !is_weakly_connected(g.graph)
        throw(GraphConnectivityError(g, "dep graphs must be weakly connected"))
    end
    for i = 1:length(g)
        n_inc = length(inneighbors(g.graph, i))
        if n_inc == 0 && head(g, i) == 0
            # root node and its dependency on predicate are
            # represented implicitly, so 0 is expected here
            continue
        elseif n_inc != 1
            msg  = "node $i should have exactly 1 incoming connection (has $n_inc)"
            throw(GraphConnectivityError(g, msg))
        end
    end
    return nothing
end

function isprojective(g::DependencyGraph, head::Int, dep::Int)
    mn, mx = min(head, dep), max(head, dep)
    for k in min(head, dep):max(head, dep)
        !has_path(g.graph, head, k) && return false
    end
    return true
end

function isprojective(g::DependencyGraph)
    # For every arc (i,l,j) there is a directed path from i to every
    # word k such that min(i,j) < k < max(i,j)
    return all([isprojective(g, src(edge), dst(edge)) for edge in edges(g.graph)])
end

dependents(g::DependencyGraph, id::Int) = iszero(id) ? [g.root] : outneighbors(g.graph, id)
deprel(g::DependencyGraph, id::Int) = deprel(g[id])
form(g::DependencyGraph, id::Int) = form(g[id])
head(g::DependencyGraph, id::Int) = head(g[id])
root(g::DependencyGraph) = g[0]

import Base.==
==(g1::DependencyGraph, g2::DependencyGraph) = all(g1.tokens .== g2.tokens)
Base.eltype(g::DependencyGraph) = eltype(g.tokens)
Base.getindex(g::DependencyGraph, i) = i == 0 ? root(eltype(g)) : g.tokens[i]
Base.length(g::DependencyGraph) = length(g.tokens)

Base.iterate(g::DependencyGraph, state=1) = iterate(g.tokens, state)
