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


struct CLENode{T}
    index::T
    incoming::BitArray
    inner::BitArray # TODO: can maybe get rid of this?
end

function CLENode(scores::AbstractMatrix, index)
    incoming = falses(size(scores))
    incoming[:, index] .= true

    inner = falses(size(scores))

    for i in index, j in index
        if i != j
            incoming[i, j] = false
            inner[i, j] = true
        end
    end
    CLENode(index, incoming, inner)
end

struct CLENodes
    nodes::Vector{CLENode}
    indexmap::Vector{Int} # original matrix indices --> nodes indices
end

function CLENodes(A::AbstractMatrix)
    indexmap = collect(1:size(A, 1))
    nodes = [CLENode(A, i) for i=1:size(A,1)]
    return CLENodes(nodes, indexmap)
end

Base.length(nodes::CLENodes) = length(nodes.nodes)
Base.iterate(nodes::CLENodes, st...) = iterate(nodes.nodes, st...)


"""
    chu_liu_edmonds(G)

todo
"""
function chu_liu_edmonds end

chu_liu_edmonds(G::DependencyGraph) = chu_liu_edmonds(G.arcs)

function chu_liu_edmonds(G::AbstractMatrix)
    return _chu_liu_edmonds(DependencyGraph(G), CLENodes(G))
end

function _chu_liu_edmonds(G, nodes)
    prediction, scores = greedy_predict(G, nodes)
    cycles = find_cycles(first.(prediction))
    if !isempty(cycles)
        cycle = pop!(cycles)
        nodes_collapsed, to_expand = combine(nodes, cycle)
        adjusted = adjust(G, nodes, scores)
        tree_collapsed, _ = _chu_liu_edmonds(adjusted, nodes_collapsed)
        corrected_arcs = expand(prediction, nodes, tree_collapsed, nodes_collapsed, to_expand)
        return corrected_arcs, sum(G[arc...] for arc in corrected_arcs)
    else
        return prediction, sum(scores)
    end
end

function greedy_predict(G, nodes)
    predictions = [choose_head(G, node) for node in nodes]
    arcs, scores = zip(predictions...)
    arcs = [(h == i ? 0 : h, i) for (h, i) in arcs]
    return arcs, collect(scores)
end

function adjust(G, nodes, values)
    A = copy(G)
    for (node, value) in zip(nodes, values)
        adjustment = node.incoming .* value
        A .-= adjustment
    end
    return A
end


function choose_head(G::AbstractMatrix, n::CLENode)
    index = argmax(i -> G[i], findall(n.incoming))
    return Tuple(index), G[index]
end

choose_head(G::AbstractMatrix, i) = choose_head(G, CLENode(G, i))

function combine(nodes, cycle)
    new_nodes = CLENode[]
    indexmap = copy(nodes.indexmap)
    index_to_expand = 0
    for (i, node) in enumerate(nodes)
        if ! (i in cycle)
            push!(new_nodes, node)
        elseif i == minimum(cycle) # combined node
            index = collect(cycle)
            cycle_nodes = nodes.nodes[index]
            
            incoming = reduce((.|), [n.incoming for n in cycle_nodes])
            inner = falses(size(first(nodes).inner))
            for i_ in index, j_ in index
                if i_ != j_
                    incoming[i_, j_] = false
                    inner[i_, j_] = true
                end
            end

            indexmap[index] .= i
            combined_node = CLENode(index, incoming, inner)
            push!(new_nodes, combined_node)
            index_to_expand = i
        end
    end
    return CLENodes(new_nodes, indexmap), index_to_expand
end

function expand(tree_cyclic, nodes_cyclic, tree_collapsed, nodes_collapsed, to_expand)
    cnode = nodes_collapsed.nodes[to_expand]
    n = length(tree_cyclic)
    arcs = Vector{Tuple{Int,Int}}(undef, n)
    for (i, ((head, index), node)) in enumerate(zip(tree_collapsed, nodes_collapsed))
        if i != to_expand
            arcs[i] = (head, index)
        else
            for c_index in cnode.index
                if c_index == index
                    arcs[c_index] = (head, index)
                else
                    arcs[c_index] = tree_cyclic[c_index]
                end
            end
        end
    end
    return arcs
end
