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

# Base.copy(G::DependencyGraph) = DependencyGraph(copy(G.arcs))

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


# decoding

# greedy_predict(G) = greedy_predict(G, 1:size(G, 1))
    
# function greedy_predict(G, nodes)
#     map(nodes) do node
#         score, head = findmax(G, node)
#         return head, score
#     end
# end

function cle(scores)
    prediction = greedy_predict(scores)
    
end

struct CLENode2
    arcs::Dict{Int,Int}
end



struct CLENode{T}
    index::T
    incoming::BitArray
    # maybe: offset (i.e., cache the minimum?)
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

# function CLENode(scores::AbstractMatrix, index)
#     incoming = trues(size(scores[:, index]))
#     return CLENode(index, incoming)
# end

# function combine(nodes...)
#     index = cat(node.index for node in nodes)
#     incoming = (|).(node.incoming for node in nodes)
#     return CLENode(index, incoming)
# end

# function expand_new(tree_collapsed, nodes_collapsed, to_expand)
#     # "The edge of the maximum spanning tree directed towards the
#     # vertex representing the collapsed cycle tells us which edge to
#     # delete in order to eliminate the cycle."
#     # 
#     # IOW, delete the edge within the cycle that goes to the node of
#     # the incoming edge from the MST.
#     node = nodes_collapsed.nodes[to_expand] # TODO: move this out?

#     n = length(tree_collapsed) + length(node.index) - 1
#     println("expanding to $n nodes")

#     expanded_arcs = zeros(Int, n)

#     offset = 0
#     for (index_expanded, index_collapsed) in enumerate(nodes_collapsed.indexmap)
#         # mst_head = tree_collapsed[
#         if mapped_index == to_expand
#         else
#         end
#     end

#     return expanded_arcs
# end

"""
    chu_liu_edmonds(G)

todo
"""
function chu_liu_edmonds end

chu_liu_edmonds(G::DependencyGraph) = chu_liu_edmonds(G.arcs)

function chu_liu_edmonds(G::AbstractMatrix)
    # nodes = [CLENode(G, i) for i in 1:size(G, 1)]
    # nodes = CLENodes(G)
    # return _chu_liu_edmonds(G, nodes)
    return _chu_liu_edmonds(DependencyGraph(G), CLENodes(G))
end

function _chu_liu_edmonds(G, nodes)
    println("hi, it's me, chu/liu-edmonds")
    @show G nodes
    @show prediction, scores = greedy_predict(G, nodes)
    @show cycles = find_cycles(first.(prediction))
    if !isempty(cycles)
        @show cycle = pop!(cycles)
        @show nodes_collapsed, to_expand = combine(nodes, cycle)
        @show adjusted = adjust(G, nodes, scores)
        @show tree_collapsed, _ = _chu_liu_edmonds(adjusted, nodes_collapsed)
        @show corrected_arcs = expand(prediction, nodes, tree_collapsed, nodes_collapsed, to_expand)
        return corrected_arcs, sum(G[arc...] for arc in corrected_arcs)
    else
        return prediction, sum(scores)
    end
end

function greedy_predict(G, nodes)
    # [argmax(G[node.incoming, node.index]) for node in nodes]
    predictions = [choose_head(G, node) for node in nodes]
    # arcs, scores = zip(triples...)
    arcs, scores = zip(predictions...)
    # heads = [h == i ? 0 : h for (h, i) in enumerate(heads)]
    arcs = [(h == i ? 0 : h, i) for (h, i) in arcs]
    # return heads, indices, collect(scores)
    return arcs, collect(scores)
end

# rename this back to choose_head?
# function ch2(G::AbstractMatrix, node::CLENode)
#     na = typemin(eltype(G))
#     best, best_score = -1, na
#     for index in eachindex(view(G, :, node.index))
#         if node.incoming[index] && G[index] > best_score
#             best, best_score = first(Tuple(index)), G[index]
#         end
#     end
#     best, best_score
# end

function adjust(G, nodes, values)
    @show G
    A = copy(G)
    for (node, value) in zip(nodes, values)
        @show adjustment = node.incoming .* value
        @show A .-= adjustment
        end
    return A
end


function choose_head(G::AbstractMatrix, n::CLENode)
    index = argmax(i -> G[i], findall(n.incoming))
    # tup = Tuple(index)
    # return first(Tuple(index)), G[index]
    # return tup[1], tup[2], G[index]
    return Tuple(index), G[index]
end

choose_head(G::AbstractMatrix, i) = choose_head(G, CLENode(G, i))
# choose_head(G::DependencyGraph, a...) = choose_head(G.arcs, a...)

# function choose_head(G::AbstractMatrix, node::CLENode)
#     # node_arcs = G[node.incoming, node.index]
#     # index = argmax(node_arcs)
#     # # findmax(node_arcs)
#     # # if node is mutiple tokens, then index will be a cartesian
#     # # index. account for this by converting to a tuple and returning
#     # # the first element.
#     # score = node_arcs[index]
#     # head = first(Tuple(index))
#     # return (head, score)
#     na = typemin(eltype(G))
#     best = -1
#     best_score = na
#     for index in eachindex(IndexCartesian(), view(G[:, node.index]))
#         @show index
#         if node.incoming[index] && G[index] > best_score
#             best, best_score = first(Tuple(index)), G[index]
#         end
#     end
#     return best, best_score
# end

function combine(nodes, cycle)
    new_nodes = CLENode[]
    # indexmap = zeros(Int, size(first(nodes).incoming, 1))
    indexmap = copy(nodes.indexmap)
    index_to_expand = 0
    for (i, node) in enumerate(nodes)
        if ! (i in cycle)
            push!(new_nodes, node)
            # indexmap[i] = length(new_nodes)
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
    

# function expand3(tree_collapsed, nodes_collapsed, to_expand)
#     node = nodes_collapsed[to_expand]
#     n = length(tree_collapsed) + length(node.index) - 1
#     arcs = -ones(Int, n)

#     # first: fill in the expanded MST for the cycle arcs, skipping the
#     # one going to the same node as the incoming arc from the
#     # collapsed MST
#     # for i in node.index, j in findall(
#         # print("looking at arc
#     # end

#     return arcs
# end

# function expand2(tree_collapsed, nodes_collapsed, to_expand)
#     # "The edge of the maximum spanning tree directed towards the
#     # vertex representing the collapsed cycle tells us which edge to
#     # delete in order to eliminate the cycle."
    
#     # in other words, delete the edge within the cycle that goes to
#     # the node of the incoming edge from the MST.
#     node = nodes_collapsed.nodes[to_expand] # TODO: move this out?

#     n = length(tree_collapsed) + length(node.index) - 1
#     println("expanding to $n nodes")

#     arcs = zeros(Int, n)
#     indexmap = nodes_collapsed.indexmap
#     println("MST: $tree_collapsed")
#     println("will expand node #$to_expand ($(node.index))")

#     expanded_offset = 0
#     mst_offset = 0
#     for i_expanded in 1:n
#         # want to set arcs[i] to complete expanded node
#         # i_n = indexmap[i]

#         i_mst = i_expanded - mst_offset

#         h_mst = tree_collapsed[i_mst]
#         println("> need to set arc $i_expanded in expanded MST")
#         println("> arc is $h_mst --> $i_mst in MST for collapsed tree")

#         # root arcs along the axis to avoid indexing at zero
#         h_mst= iszero(mst_head) ? i_mst : h_mst

#         if i_mst == to_expand
#             println("in collapsed node")
#             # println("
#         else
#             println("NOT looking at collapsed node.")
#             println("using arc from the collapsed MST: $h_mst --> $i_mst ($(h_mst + mst_offset) --> i_expanded in expanded tree)")

#             arcs[i_expanded] = mst_head + mst_offset
#         end
#     end
# end

# function expand(tree_collapsed, nodes_collapsed, to_expand)
#     # "The edge of the maximum spanning tree directed towards the
#     # vertex representing the collapsed cycle tells us which edge to
#     # delete in order to eliminate the cycle."
    
#     # in other words, delete the edge within the cycle that goes to
#     # the node of the incoming edge from the MST.
#     node = nodes_collapsed.nodes[to_expand] # TODO: move this out?

#     n = length(tree_collapsed) + length(node.index) - 1
#     println("expanding to $n nodes")

#     arcs = zeros(Int, n)
#     indexmap = nodes_collapsed.indexmap
#     println("MST: $tree_collapsed")
#     println("will expand node #$to_expand ($(node.index))")

#     expanded_offset = 0
#     mst_offset = 0
#     for i_expanded in 1:n
#         # want to set arcs[i] to complete expanded node
#         # i_n = indexmap[i]

#         i_mst = i_expanded - mst_offset

#         mst_head = tree_collapsed[i_mst]
#         println("> {$i_expanded} need to set arc h --> $i_expanded in expanded MST")
#         println("> arc is $mst_head --> $i_mst in MST for collapsed tree")

#         # root arcs are along the axis to avoid indexing at zero
#         mst_head = iszero(mst_head) ? i_mst : mst_head

#         if i_mst == to_expand
#             println("on the collapsed node. is coming from the cycle (?)")
#             # println("arc in collapsed node is: ($mst_head --> $i_mst)")
#             for i_collapsed in node.index
#                 if node.incoming[i_mst, i_collapsed]
#                     println(">> $i_collapsed --> $i_mst: yes!")
#                 else
#                     println(">> $i_collapsed --> $i_mst: no!")
#                 end
#             end

#             # drop_from_cycle = !node.incoming[mst_head, i_mst]
#             drop_from_cycle = node.inner[mst_head, i_mst]
#             println("does this compete with MST? $drop_from_cycle")
#             if drop_from_cycle
#                 # use the MST arc
#                 println("using the MST arc! setting $(mst_head+mst_offset) --> $i_expanded")
#                 arcs[i_expanded] = mst_head + mst_offset
#             else
#                 # arcs[i] =
#                 println("need to set arcs[i] to the arc from inside the cycle?")
#                 # TODO
#                 println("setting arc () --> $i_expanded")
#                 # arcs[i_expanded] = 
#                 mst_offset += 1
#             end
#         else
#             arcs[i_expanded] = mst_head + mst_offset
#             println("not the node to expand. using MST arc $(arcs[i_expanded]) --> $i_expanded")
#         end
        

#         # nodes_collapsed has:
#         # - vector of nodes of the collapsed tree
#         # - mapping of collapsed index to original nodes
#         # - mapping of original nodes to collapsed nodes
       
        
#         # mst_h = tree_collapsed[i]
#         # inc = incomingarc(
#         # if n.incoming[mst_h, i]
#     end
#     return arcs
# end

# function incomingarc(node, h, i)
#     # account for the root node
#     if iszero(h)
#         h = i
#     end
#     @show is_incoming && i in node.index
# end
