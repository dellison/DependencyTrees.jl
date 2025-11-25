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
    n = size(A, 1)
    indexmap = collect(1:n)
    nodes = [CLENode(A, i) for i=1:n]
    return CLENodes(nodes, indexmap)
end

Base.length(nodes::CLENodes) = length(nodes.nodes)
Base.iterate(nodes::CLENodes, st...) = iterate(nodes.nodes, st...)

function mapindex(nodes::CLENodes, graph_index)
    node_index = nodes.indexmap[graph_index]
    return node_index
end

function mapindices(nodes::CLENodes, graph_indices...)
    node_indices = (mapindex(nodes, index) for index in graph_indices)
    return node_indices
end

function maparc(nodes::CLENodes, h, i; head_zero=true)
    iszero(h) && (h = i)
    nh = nodes.indexmap[h]
    ni = nodes.indexmap[i]
    if head_zero && nh == ni
        nh = 0
    end
    return (nh, ni)
end

maparcs(nodes::CLENodes, arcs; head_zero=true) =
    [maparc(nodes, h, i; head_zero=head_zero) for (h, i) in arcs]

"""
    chu_liu_edmonds(G)

todo
"""
function chu_liu_edmonds end

chu_liu_edmonds(G::DependencyGraph) =
    _chu_liu_edmonds(G, CLENodes(G))

chu_liu_edmonds(G::AbstractMatrix) =
    _chu_liu_edmonds(DependencyGraph(G), CLENodes(G))

function _chu_liu_edmonds(G::DependencyGraph, nodes)
    arcs, scores = greedy_predict(G, nodes)
    cycles = find_cycles(first.(maparcs(nodes, arcs; head_zero=false)))
    if !isempty(cycles)
        cycle = pop!(cycles)
        nodes_collapsed, to_expand = combine(nodes, cycle)
        adjusted = adjust(G, nodes, scores)
        tree_collapsed, _ = _chu_liu_edmonds(adjusted, nodes_collapsed)
        corrected_arcs = expand(arcs, nodes, tree_collapsed, nodes_collapsed, to_expand)
        score = sum(G[arc...] for arc in corrected_arcs)
        return corrected_arcs, score
    else
        return arcs, sum(scores)
    end
end

function greedy_predict(G, nodes; head_zero=true)
    predict = node -> choose_head(G, node; head_zero=head_zero)
    arcs, scores = collect.(zip(predict.(nodes)...))
    return arcs, scores
end

function adjust(G, nodes, values)
    A = copy(G)
    for (node, value) in zip(nodes, values)
        adjustment = node.incoming .* value
        A .-= adjustment
    end
    return A
end


function choose_head(G::AbstractMatrix, n::CLENode; head_zero=true)
    index = argmax(i -> G[i], findall(n.incoming))
    score = G[index]
    h, i, _... = Tuple(index)
    if h == i && head_zero
        h = 0
    end
    return (h, i), score
end

choose_head(G::AbstractMatrix, i) = choose_head(G, CLENode(G, i))

function combine(nodes, cycle)
    new_nodes = CLENode[]
    indexmap = copy(nodes.indexmap)
    index_to_expand = 0
    offset = 0
    for (i, node) in enumerate(nodes)
        if ! (i in cycle)
            push!(new_nodes, node)
            for idx in node.index
                indexmap[idx] = i - offset
            end
        elseif i == minimum(cycle) # combined node
            index = collect(cycle)
            cycle_nodes = nodes.nodes[index]
            
            incoming = reduce((.|), [n.incoming for n in cycle_nodes])
            for i_ in index, j_ in index
                if i_ != j_
                    incoming[i_, j_] = false
                end
            end

            for cnode in cycle, idx in nodes.nodes[cnode].index
                indexmap[idx] = i
            end
            indices = [nodes.nodes[i].index for i in cycle]
            combined_node = CLENode(reduce(vcat, indices), incoming)
            push!(new_nodes, combined_node)
            index_to_expand = i
        else
            offset += 1
        end
    end
    return CLENodes(new_nodes, indexmap), index_to_expand
end

function expand(tree_cyclic, nodes_cyclic, tree_collapsed, nodes_collapsed, to_expand)
    n = length(tree_cyclic)
    arcs = Vector{Tuple{Int,Int}}(undef, n)
    for (i, ((head, index), node)) in enumerate(zip(tree_collapsed, nodes_collapsed))
        if i != to_expand
            # node from collapsed tree, doesn't need expanding.
            hd, idx = maparc(nodes_collapsed, head, index, head_zero=true)
            i_ = mapindex(nodes_cyclic, first(node.index))
            arcs[i_] = (hd, idx)
        else
            # this is the node that was combined previously. because
            # it is made from a cycle in the tree, it has a set of
            # inner arcs, one coming in to each "sub-node." it also
            # has an arc coming into it as a part of the MST. this arc
            # "conflicts" with one of the inner arcs, as they each
            # travel to the same sub-node; therefore, when expanding
            # the nodes again, we use the incoming MST arc to the
            # collapsed node, and the rest of the "inner" arcs,
            # dropping the conflicting one.
            cnode = nodes_collapsed.nodes[to_expand]
            for c_index in cnode.index
                arc_index = mapindex(nodes_cyclic, c_index)
                if c_index == index
                    # this arc, (head --> index), is the incoming arc
                    # to the collapsed node in the MST.
                    arcs[arc_index] = (head, index)
                else
                    # this arc is an "inner arc" in the
                    # cyclic/collapsed node, so thoose that.
                    hd, idx = tree_cyclic[mapindex(nodes_cyclic, c_index)]
                    arcs[arc_index] = (hd, idx)
                end
            end
        end
    end
    return arcs
end

function expand2(tree_cyclic, nodes_cyclic, tree_collapsed, nodes_collapsed, to_expand)
    n = length(tree_cyclic)
    arcs = Vector{Tuple{Int,Int}}(undef, n)
    cnodes = zip(tree_collapsed, nodes_collapsed)
    for (i, ((head, index), node)) in enumerate(cnodes)
    end
end 
