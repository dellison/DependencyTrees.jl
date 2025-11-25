#

"""
    chu_liu_edmonds(G)

Decode a dependency tree using the Chu-Liu/Edmonds algorighm.
"""
function chu_liu_edmonds end

function chu_liu_edmonds(G::DependencyGraph)
    mst, score = _chu_liu_edmonds(G, CLENodes(G))
    return DependencyTree(mst), score
end

chu_liu_edmonds(G::AbstractMatrix) =
    chu_liu_edmonds(DependencyGraph(G))

function _chu_liu_edmonds(G::DependencyGraph, nodes)
    arcs, scores = greedy_predict(G, nodes)
    cycles = find_cycles(first.(maparcs(nodes, arcs; head_zero=false)))
    if !isempty(cycles)
        cycle = pop!(cycles)
        nodes2 = combine(nodes, cycle)
        tree2, _ = _chu_liu_edmonds(adjust(G, nodes, scores), nodes2)
        arcs2 = expand(arcs, nodes, tree2, nodes2)
        score = sum(G[arc...] for arc in arcs2)
        return arcs2, score
    else
        return arcs, sum(scores)
    end
end

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
    toexpand::Int
end

function CLENodes(A::AbstractMatrix)
    n = size(A, 1)
    indexmap = collect(1:n)
    nodes = [CLENode(A, i) for i=1:n]
    return CLENodes(nodes, indexmap, 0)
end

Base.length(nodes::CLENodes) = length(nodes.nodes)
Base.iterate(nodes::CLENodes, st...) = iterate(nodes.nodes, st...)

function mapindex(nodes::CLENodes, graph_index)
    node_index = nodes.indexmap[graph_index]
    return node_index
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

function greedy_predict(G, nodes; head_zero=true)
    predict = node -> choose_head(G, node; head_zero=head_zero)
    arcs, scores = collect.(zip(predict.(nodes)...))
    return arcs, scores
end

function adjust(G, nodes, values)
    A = copy(G)
    for (node, value) in zip(nodes, values)
        A .-= node.incoming .* value
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
            indexmap[[node.index...]] .= i - offset
        elseif i == minimum(cycle) # combined node
            index = collect(cycle)
            cnodes = nodes.nodes[index]
            
            incoming = reduce((.|), [n.incoming for n in cnodes])
            for i_ in index, j_ in index
                if i_ != j_
                    incoming[i_, j_] = false
                end
            end

            for cnode in cnodes, idx in cnode.index
                indexmap[idx] = i
            end
            indices = [node.index for node in cnodes]
            combined_node = CLENode(reduce(vcat, indices), incoming)
            push!(new_nodes, combined_node)
            index_to_expand = i
        else
            offset += 1
        end
    end
    return CLENodes(new_nodes, indexmap, index_to_expand)
end

function expand(tree_cyclic, nodes_cyclic, tree_collapsed, nodes_collapsed)
    n = length(tree_cyclic)
    arcs = Vector{Tuple{Int,Int}}(undef, n)
    for (i, ((head, index), node)) in enumerate(zip(tree_collapsed, nodes_collapsed))
        if i != nodes_collapsed.toexpand
            # node from collapsed tree, doesn't need expanding.
            hd, idx = maparc(nodes_collapsed, head, index, head_zero=true)
            treeindex = mapindex(nodes_cyclic, first(node.index))
            arcs[treeindex] = (hd, idx)
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
            cnode = nodes_collapsed.nodes[nodes_collapsed.toexpand]
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
