struct DependencyGraph{W}
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

getarc(G::DependencyGraph, head, dep) = getindex(G, head, dep)

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


# cycle detection

function tarjan(graph::Vector{Int})
    n = length(graph)
    edges = [Set{Int}() for _=1:n]
    for (i, h) in enumerate(graph)
        push!(edges[i], h)
    end
    indices  = -ones(Int, n)
    lowlinks = -ones(Int, n)
    onstack  = falses(n)
    stack    = Int[]
    index    = 0
    sccs     = Set{Int}[]
    function strongconnect(v, index, stack)
        indices[v] = index
        lowlinks[v] = index
        index += 1
        push!(stack, v)
        onstack[v] = true
        for w in edges[v]
            if indices[w] < 0
                strongconnect(w, index, stack)
                lowlinks[v] = min(lowlinks[v], lowlinks[w])
            elseif onstack[w]
                lowlinks[v] = min(lowlinks[v], indices[w])
            end
        end
        if lowlinks[v] == indices[v]
            scc = Set{Int}()
            while stack[end] != v
                w = pop!(stack)
                onstack[w] = false
                push!(scc, w)
            end
            w = pop!(stack)
            onstack[w] = false
            push!(scc, w)
            push!(sccs, scc)
        end
    end
    for v in 1:n
        if indices[v] < 0
            strongconnect(v, index, stack)
        end
    end
    return sccs
end
