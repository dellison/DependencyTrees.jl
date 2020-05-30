
# TODO keep track of outgoing arcs?
"""
    DependencyTree

A rooted tree of dependency relations among the tokens of a sentence.
"""
struct DependencyTree{T<:Token, R<:Union{Int,Set{Int}}}
    tokens::Vector{T}
    root::R
    # inc::Vector{Set{Int}}
end

"""
    deptree(read_token, xs)

Create a `DependencyTree` by calling `read_token` on each of `xs`.
"""
function deptree end

function deptree(tokens)
    return DependencyTree(tokens, find_root(tokens))
end

function deptree(read_token, xs)
    tokens = map(xs) do x
        try
            read_token(x)
        catch err
            if err isa EmptyTokenError
                nothing #
            elseif err isa MultiWordTokenError
                nothing #
            else
                throw(err)
            end
        end
    end
    tokens = Token[t for t in tokens if t !== nothing]
    root = find_root(tokens)
    return DependencyTree(tokens, root)#, multiwordtokens, emptytokens)
end

function deptree(lines::String, read_token=from_conllu)
    lines = [line for line in split(strip(lines), "\n")]
    lines = filter(x -> !startswith(x, "#"), lines)
    return deptree(read_token, lines)
end

function find_root(tokens)
    root = [i for (i, token) in enumerate(tokens) if has_head(token, 0)]
    return length(root) == 1 ? root[1] : Set(root)
end

function arcs(tree::DependencyTree)
    inc = incoming(tree)
    T = length(tree)
    return [(s, d) for d in 1:T for s in inc[d]]
end

deps(tree::DependencyTree, i::Int) =
    filter(j -> has_head(tree.tokens[j], i), 1:length(tree))

leftdeps(tree::DependencyTree, i::Int) = filter(j -> j < i, deps(tree, i))

function leftmostdep(tree::DependencyTree, i::Int)
    ds = leftdeps(tree, i)
    isempty(ds) ? -1 : first(ds)
end

rightdeps(tree::DependencyTree, i::Int) = filter(j -> j > i, deps(tree, i))

function rightmostdep(tree::DependencyTree, i::Int)
    ds = rightdeps(tree, i)
    isempty(ds) ? -1 : last(ds)
end

has_arc(tree::DependencyTree, head::Int, dependant::Int) =
    iszero(dependant) ? false : has_head(tree.tokens[dependant], head)

function incoming(tree::DependencyTree)
    inc = [Set{Int}() for _=1:length(tree)]
    for (i, token) in enumerate(tree), head in token.head
        push!(inc[i], head)
    end
    return inc
end

token(tree::DependencyTree, i) =
    iszero(i) ? ROOT : tree.tokens[i]

function is_projective(tree::DependencyTree)
    # For every arc (i,l,j) there is a directed path from i to every
    # word k such that min(i,j) < k < max(i,j)
    arc = (a, b) -> has_arc(tree, a, b)
    for (parent, child) in arcs(tree)
        child > parent && ((child, parent) = (parent, child))
        for k in child+1:parent-1
            for m in 1:length(tree)#Iterators.flatten((1:i-1, j+1:length(tree)))
                if m < child || m > parent
                    if arc(k, m) || arc(m, k)
                        return false
                    end
                end
            end
        end
    end
    return true
end
    
Base.getindex(tree::DependencyTree, i::Int) = iszero(i) ? ROOT : tree.tokens[i]

Base.iterate(tree::DependencyTree, state...) = iterate(tree.tokens, state...)

Base.length(tree::DependencyTree) = length(tree.tokens)

Base.show(io::IO, tree::DependencyTree) =
    print(io, "DependencyTree: ", join((t.form for t in tree.tokens), " "))
    
==(a::DependencyTree, b::DependencyTree) = all(a.tokens .== b.tokens)
