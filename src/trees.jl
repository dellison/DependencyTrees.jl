"""
    DependencyTree

A natural language sentence annotated with dependency structure.
"""
struct DependencyTree{T<:Dependency} <: AbstractGraph{Int}
    graph::SimpleDiGraph
    tokens::Vector{T}
    mwts::Vector{MultiWordToken}
    emptytokens::Vector{EmptyToken}
    root::Int

    function DependencyTree(graph, tokens, mwts, emptytokens, root; check=true, kwargs...)
        g = new{eltype(tokens)}(graph, tokens, mwts, emptytokens, root)
        check && check_tree(g; kwargs...)
        return g
    end
end

"""
   DependencyTree(T, tokens; add_id=false; kwargs...)

Make a dependency tree with tokens of type `T` from `tokens`.
"""
function DependencyTree(T::Type{<:Dependency}, tokens; add_id=false, kwargs...)
    A, mwts, es = T[], MultiWordToken[], EmptyToken[]
    for (id, token) in enumerate(tokens)
        add_id ? dependency = T(id, token...) : dependency = T(token...)
        push!(A, dependency)
    end
    DependencyTree(A; mwts=mwts, emptytokens=es, kwargs...)
end

function DependencyTree(tokens::Vector{<:Dependency}; mwts=MultiWordToken[], emptytokens=EmptyToken[], kwargs...)
    rt = 0
    graph = SimpleDiGraph(length(tokens))
    for dep in tokens
        isroot(dep) && continue
        i, h = id(dep), head(dep)
        iszero(h) && (rt = i)
        add_edge!(graph, h, i) # arrows point from head to dependent
    end
    return DependencyTree(graph, tokens, mwts, emptytokens, rt; kwargs...)
end

function DependencyTree{T}(lines::AbstractVector{S}; add_id=false, kwargs...) where {T<:Dependency,S<:AbstractString}
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
    DependencyTree(A; mwts=mwts, emptytokens=emptytokens, kwargs...)
end

"""
    DependencyTree{T}(sentence::String; add_id=false, kwargs...)

Read a dependency tree from `sentence`.
"""
function DependencyTree{T}(sentence::String; add_id=false, kwargs...) where T
    ls = String.(filter(x -> x != "", split(strip(sentence), "\n")))
    DependencyTree{T}(ls; add_id=false, kwargs...)
end

"""
    check_tree(g, check_single_head=true, check_has_root=true, check_projective=false)

Ensure the well-formedness of the dependency graph `g`, throwing an
error if g is not well-formed.
"""
function check_tree(tree::DependencyTree; check_single_head=true, check_has_root=true,
                        check_projective=false)
    check_has_root && iszero(tree.root) && throw(RootlessGraphError(tree))
    if check_single_head
        !has1root(tree) && throw(MultipleRootsError(tree))
        !is_weakly_connected(tree.graph) && throw(GraphConnectivityError(tree,"not weakly connected!"))    
    end
    check_projective && !isprojective(tree) && throw(NonProjectiveGraphError(tree))
    for i in 1:length(tree)
        n_inc = length(inneighbors(tree.graph, i))
        # root node and its dependency on predicate are
        # represented implicitly, so 0 is expected here
        n_inc == 0 && head(tree, i) == 0 ? continue :
        n_inc != 1 && throw(GraphConnectivityError(tree, "node $i should have exactly 1 incoming connection (has $n_inc)"))
    end
    return nothing
end

has1root(tree::DependencyTree) = count(iszero ∘ head, tokens(tree)) == 1

isprojective(tree::DependencyTree) =
    # For every arc (i,l,j) there is a directed path from i to every
    # word k such that min(i,j) < k < max(i,j)
    all(isprojective(tree, src(e), dst(e)) for e in edges(tree.graph))

isprojective(g::DependencyTree, head::Int, dep::Int) =
    all(k -> has_path(g.graph, head, k), min(head, dep):max(head, dep))

dependents(g::DependencyTree, id::Int) =
    iszero(id) ? [g.root] : outneighbors(g.graph, id)
deprel(g::DependencyTree, id::Int) = deprel(g[id])
deptype(g::DependencyTree) = eltype(g.tokens)
form(g::DependencyTree, id::Int) = form(g[id])
has_arc(g::DependencyTree, h::Int, d::Int) = head(g[d]) == h
has_dependency(g::DependencyTree, h::Int, d::Int) = head(g[d]) == h
head(g::DependencyTree, id::Int) = head(g[id])
root(g::DependencyTree) = g[0]
token(g::DependencyTree, id) = g[id]
tokens(g::DependencyTree) = g.tokens
tokens(g::DependencyTree, is) = [token(g, i) for i in is if 0 <= i <= length(g)]

function leftdeps(g::DependencyTree, dep::Dependency)
    i = id(dep)
    g[filter(d -> d < i, dependents(g, id(dep)))]
end
leftdeps(g::DependencyTree, i::Int) = filter(d -> d < i, dependents(g, i))

function rightdeps(g::DependencyTree, dep::Dependency)
    i = id(dep)
    g[filter(d -> d > i, dependents(g, id(dep)))]
end
rightdeps(g::DependencyTree, i::Int) = filter(d -> d > i, dependents(g, i))

leftmostdep(g::DependencyTree, args...) = leftmostdep(g.tokens, args...)
rightmostdep(g::DependencyTree, args...) = rightmostdep(g.tokens, args...)

toconllu(g::DependencyTree) = string(toconllu.(g)...)

function Base.show(io::IO, g::DependencyTree)
    T = "DependencyTree{$(eltype(g))}\n"
    token(t) = "$(id(t))\t$(form(t))\t$(deprel(t))\t$(head(t))"
    print(io,T,join([token(t) for t in g],"\n"))
end
function Base.show(io::IO, g::DependencyTree{UntypedDependency})
    T = "DependencyTree{$(eltype(g))}\n"
    token(t) = "$(id(t))\t$(form(t))\t$(head(t))"
    print(io,T,join([token(t) for t in g],"\n"))
end

==(g1::DependencyTree, g2::DependencyTree) = all(g1.tokens .== g2.tokens)
Base.eltype(g::DependencyTree) = eltype(g.tokens)
Base.getindex(g::DependencyTree, i) = i == 0 ? root(eltype(g)) : g.tokens[i]
Base.iterate(g::DependencyTree, state=1) = iterate(g.tokens, state)
Base.length(g::DependencyTree) = length(g.tokens)
