struct DependencyGraph{T<:Dependency} <: AbstractGraph{Int}
    graph::SimpleDiGraph
    tokens::Vector{T}
    mwts::Vector{MultiWordToken}
    emptytokens::Vector{EmptyToken}
    root::Int

    function DependencyGraph(graph, tokens, mwts, emptytokens, root; check=true, kwargs...)
        g = new{eltype(tokens)}(graph, tokens, mwts, emptytokens, root)
        check && check_depgraph(g; kwargs...)
        return g
    end
end

"""
    DependencyGraph(T::Type{<:Dependency}, tokens)

Create a DependencyGraph for dependencies of type t with
nodes `tokens`.

DependencyGraph(UntypedDependency, [(\"the\", 2),(\"cat\",3),(\"slept\",0)])

DependencyGraph(TypedDependency, [(\"the\", \"DT\", 2),(\"cat\",\"NN\",3),(\"slept\",\"VBD\",0)])
"""
function DependencyGraph(T::Type{<:Dependency}, tokens; add_id=false, kwargs...)
    A, mwts, es = T[], MultiWordToken[], EmptyToken[]
    for (i, token) in enumerate(tokens)
        if add_id
            dependency = T(i, token...)
        else
            dependency = T(token...)
        end
        push!(A, dependency)
    end
    DependencyGraph(A; mwts=mwts, emptytokens=es, kwargs...)
end

function DependencyGraph(tokens::Vector{<:Dependency}; mwts=MultiWordToken[], emptytokens=EmptyToken[], kwargs...)
    rt = 0
    graph = SimpleDiGraph(length(tokens))
    for dep in tokens
        isroot(dep) && continue
        i, h = id(dep), head(dep)
        iszero(h) && (rt = i)
        add_edge!(graph, h, i) # arrows point from head to dependent
    end
    return DependencyGraph(graph, tokens, mwts, emptytokens, rt; kwargs...)
end

function DependencyGraph{T}(lines::AbstractVector{S}; add_id=false, kwargs...) where {T<:Dependency,S<:AbstractString}
    A, mwts, emptytokens = T[], MultiWordToken[], EmptyToken[]
    for (i, line) in enumerate(lines)
        try
            push!(A, T(line, add_id=add_id))
        catch err
            if isa(err, MultiWordTokenError)
                push!(mwts, MultiWordToken(line))
            elseif isa(err, EmptyTokenError)
                push!(emptytokens, EmptyToken(line))
            else
                throw(err)
            end
        end
    end
    DependencyGraph(A; mwts=mwts, emptytokens=emptytokens, kwargs...)
end

function DependencyGraph{T}(lines::String; add_id=false, kwargs...) where T
    ls = String.(filter(x -> x != "", split(strip(lines), "\n")))
    DependencyGraph{T}(ls; add_id=false, kwargs...)
end

"""
    check_depgraph(g, check_single_head=true, check_has_root=true, check_projective=false)

Ensure the well-formedness of the dependency graph `g`, throwing an
error if g is not well-formed.
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

dependents(g::DependencyGraph, id::Int) =
    iszero(id) ? [g.root] : outneighbors(g.graph, id)
deprel(g::DependencyGraph, id::Int) = deprel(g[id])
deptype(g::DependencyGraph) = eltype(g.tokens)
form(g::DependencyGraph, id::Int) = form(g[id])
has_arc(g::DependencyGraph, h::Int, d::Int) = head(g[d]) == h
has_dependency(g::DependencyGraph, h::Int, d::Int) = head(g[d]) == h
head(g::DependencyGraph, id::Int) = head(g[id])
root(g::DependencyGraph) = g[0]
token(g::DependencyGraph, id) = g[id]

function leftdeps(g::DependencyGraph, dep::Dependency)
    i = id(dep)
    filter(d -> id(d) < i, dependents(g, dep))
end
leftdeps(g::DependencyGraph, i::Int) = filter(d -> d < i, dependents(g, i))

function rightdeps(g::DependencyGraph, dep::Dependency)
    i = id(dep)
    filter(d -> id(d) > i, dependents(g, dep))
end
rightdeps(g::DependencyGraph, i::Int) = filter(d -> d > i, dependents(g, i))

leftmostdep(g::DependencyGraph, args...) = leftmostdep(g.tokens, args...)
rightmostdep(g::DependencyGraph, args...) = rightmostdep(g.tokens, args...)

import Base.==
==(g1::DependencyGraph, g2::DependencyGraph) = all(g1.tokens .== g2.tokens)
Base.eltype(g::DependencyGraph) = eltype(g.tokens)
Base.getindex(g::DependencyGraph, i) = i == 0 ? root(eltype(g)) : g.tokens[i]
Base.iterate(g::DependencyGraph, state=1) = iterate(g.tokens, state)
Base.length(g::DependencyGraph) = length(g.tokens)
