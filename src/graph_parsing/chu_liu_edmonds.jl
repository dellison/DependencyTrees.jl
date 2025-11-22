struct CLENode{T}
    index::T
    incoming::BitArray
end

function CLENode(scores::AbstractMatrix, index)
    incoming = falses(size(scores))
    incoming[:, index] .= true

    for i in index, j in index
        if i != j
            incoming[i, j] = false
        end
    end
    CLENode(index, incoming)
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
            for i_ in index, j_ in index
                if i_ != j_
                    incoming[i_, j_] = false
                end
            end

            indexmap[index] .= i
            combined_node = CLENode(index, incoming)
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
