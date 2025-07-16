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


# decoding

struct CLENode{T}
    index::T
    incoming::BitVector
end

function CLENode(scores::AbstractMatrix, index)
    incoming = trues(size(scores, 1))
    for i in index
        incoming[i] = false
    end
    return CLENode(index, incoming)
end

function combine(nodes...)
    index = cat(node.index for node in nodes)
    incoming = (|).(node.incoming for node in nodes)
    return CLENode(index, incoming)
end


"""
    chu_liu_edmonds(G)

todo
"""
function chu_liu_edmonds end

chu_liu_edmonds(G::DependencyGraph) = chu_liu_edmonds(G.arcs)

function chu_liu_edmonds(G::AbstractMatrix)
    nodes = [CLENode(G, i) for i in 1:size(G, 1)]
    return _chu_liu_edmonds(G, nodes)
end

function _chu_liu_edmonds(G, nodes)
    prediction = greedy_predict(G, nodes)
    cycles = find_cycles(prediction)
    if !isempty(cycles)
        cycle = pop!(cycles)
        # recurse (todo lol)
    else
        return prediction
    end
end

greedy_predict(G, nodes) =
    [argmax(G[node.incoming, node.index]) for node in nodes]
