struct DependencyGraph{T<:Dependency} <: AbstractGraph{Int}
    graph::SimpleDiGraph
    tokens::Vector{T}
    root::Int

    function DependencyGraph(graph, tokens, root; check=true, kwargs...)
        g = new{eltype(tokens)}(graph, tokens, root)
        check && check_depgraph(g; kwargs...)
        return g
    end
end

"""
    DependencyGraph(t::Type{<:Dependency}, tokens)

Create a DependencyGraph for dependencies of type t with
nodes `tokens`.

```julia
DependencyGraph(UntypedDependency, [(\"the\", 2),(\"cat\",3),(\"slept\",0)])

DependencyGraph(TypedDependency, [(\"the\", \"DT\", 2),(\"cat\",\"NN\",3),(\"slept\",\"VBD\",0)])
```
"""
function DependencyGraph(t::Type{<:Dependency}, tokens; add_id=true, kwargs...)
    A = t[]
    for (i, token) in enumerate(tokens)
        try
            if add_id
                dependency = t(i, token...)
            else
                dependency = t(token...)
            end
            push!(A, dependency)
        catch err
            if isa(err, MultiWordTokenError)
                @warn "Multiword tokens are not yet supported" token=token
                continue
            elseif isa(err, EmptyNodeError)
                @warn "Empty nodes are not yet supported" token=token
                continue
            end
        end
    end
    DependencyGraph(A; kwargs...)
end

function DependencyGraph(tokens::Vector{<:Dependency}; kwargs...)
    rt = 0
    graph = SimpleDiGraph(length(tokens))
    for dep in tokens
        isroot(dep) && continue
        i, h = id(dep), head(dep)
        iszero(h) && (rt = i)
        add_edge!(graph, h, i) # arrows point from head to dependent
    end
    return DependencyGraph(graph, tokens, rt; kwargs...)
end

"""
    check_depgraph(g, 
"""
function check_depgraph(g::DependencyGraph; check_single_head=true, check_has_root=true,
                        check_projective=false)
    check_has_root && iszero(g.root) && throw(RootlessGraphError(g))
    if check_single_head
        if count(t -> iszero(head(t)), g.tokens) > 1
            throw(MultipleRootsError(g))
        end
        if !is_weakly_connected(g.graph)
            throw(GraphConnectivityError(g, "dep graphs must be weakly connected"))
        end
    end
    check_projective && !isprojective(g) && throw(NonProjectiveGraphError(g))
    for i = 1:length(g)
        n_inc = length(inneighbors(g.graph, i))
        # root node and its dependency on predicate are
        # represented implicitly, so 0 is expected here
        n_inc == 0 && head(g, i) == 0 ? continue :
        n_inc != 1 && throw(GraphConnectivityError(g, "node $i should have exactly 1 incoming connection (has $n_inc)"))
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
has_dependency(g::DependencyGraph, h::Int, d::Int) = head(g[d]) == h
head(g::DependencyGraph, id::Int) = head(g[id])
root(g::DependencyGraph) = g[0]
token(g::DependencyGraph, id) = g[id]

import Base.==
==(g1::DependencyGraph, g2::DependencyGraph) = all(g1.tokens .== g2.tokens)
Base.eltype(g::DependencyGraph) = eltype(g.tokens)
Base.getindex(g::DependencyGraph, i) = i == 0 ? root(eltype(g)) : g.tokens[i]
Base.length(g::DependencyGraph) = length(g.tokens)

Base.iterate(g::DependencyGraph, state=1) = iterate(g.tokens, state)
