# cycle detection

function find_cycles(graph::Vector{Int})
    sccs = tarjan(graph)
    return filter(scc -> length(scc) > 1, sccs)
end

has_cycles(graph::Vector{Int}) =
    any(scc -> length(scc) > 1, tarjan(graph))


"""
    tarjan(tree)

Find strongly-connected components using Tarjan's algorithm.
"""
function tarjan end

tarjan(G::DependencyTree) = tarjan(G.arcs)

function tarjan(graph::Vector{Int})
    n = length(graph)
    # edges[i] is the set of the dependent tokens
    edges = [Set{Int}() for _=1:n]
    for (i, h) in enumerate(graph)
        iszero(h) || push!(edges[h], i)
    end
    indices = -ones(Int, n)
    lowlinks = -ones(Int, n)
    index = 1
    onstack = falses(n)
    stack = Int[]
    sccs = Set{Int}[]
    function strongconnect(v)
        # set the depth index for v to the smallest unused index
        indices[v] = index
        lowlinks[v] = index
        index += 1
        push!(stack, v)
        onstack[v] = true
        for w in edges[v]
            if indices[w] < 0
                # Successor w has not yet been visited; recurse on it
                strongconnect(w)
                lowlinks[v] = min(lowlinks[v], lowlinks[w])
            elseif onstack[w]
                # w is in the stack, therefore in the current SCC.  If
                # w is not on stack, then (v, w) is an edge pointing
                # to an SCC already found and must be ignored
                lowlinks[v] = min(lowlinks[v], indices[w])
            end
        end
        # if v is a root node, pop the stack and generate an SCC
        if lowlinks[v] == indices[v]
            scc = Set{Int}()
            while true
                w = pop!(stack)
                onstack[w] = false
                push!(scc, w)
                w == v && break
            end
            push!(sccs, scc)
        end
    end
    for v in 1:n
        if indices[v] < 0
            strongconnect(v)
        end
    end
    return sccs    
end
