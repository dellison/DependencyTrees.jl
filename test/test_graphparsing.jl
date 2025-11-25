@testset "Graph Parsing" begin

    using DependencyTrees.GraphParsing: DependencyGraph, getarc

    @testset "Cycle Detection" begin
        @testset "Tarjan's Algorithm" begin
            using DependencyTrees.GraphParsing: tarjan, find_cycles, has_cycles

            @testset "One Cycle" begin
                @testset "1 2" begin
                    sccs = tarjan([2, 1])
                    cycles = find_cycles([2, 1])
                    @test sccs == cycles
                    @test Set([1, 2]) in cycles
                    @test length(cycles) == 1
                end
                @testset "1 2 3" begin
                    cycles = tarjan([2, 3, 1])
                    @test Set([1, 2, 3]) in cycles
                    @test length(cycles) == 1
                end
            end

            @testset "Two Cycles" begin
                cycles = tarjan([2, 1, 4, 3])
                @test Set([1, 2]) in cycles
                @test Set([3, 4]) in cycles
                @test length(cycles) == 2
            end

            @testset "'Eat!'" begin
                # e.g., a sentence like "stop!" or "eat!"
                sccs = tarjan([0])
                cycles = find_cycles([0])
                @test length(sccs) == 1
                @test length(cycles) == 0
            end

            @testset "'I ate.'" begin
                tree = [2, 0]
                sccs = tarjan(tree)
                cycles = find_cycles(tree)
                # @show tree cycles
                @test length(sccs) == length(tree)
                @test length(cycles) == 0
            end

            @testset "'I ate fish'" begin
                tree = [2, 0, 2]
                sccs = tarjan(tree)
                cycles = find_cycles(tree)
                @test length(sccs) == length(tree)
                @test length(cycles) == 0
            end

            @testset "I ate fish with ketchup" begin
                tree = [2, 0, 2, 3, 4, 2]
                sccs = tarjan(tree)
                cycles = find_cycles(tree)
                @test length(sccs) == length(tree)
                @test length(cycles) == 0
            end
        end
    end

    @testset "Chu-Liu/Edmonds Algorithm" begin

        @testset "Combining Nodes" begin
            using DependencyTrees.GraphParsing: CLENode, CLENodes, combine

            @testset "Repeated Combines" begin
                @testset "At the end" begin
                    G = zeros(5, 5)
                    nodes = CLENodes(G)

                    @test length(nodes) == 5
                    @test nodes.indexmap == [1,2,3,4,5]

                    c_45, c_45c = combine(nodes, [4, 5])
                    @test c_45.indexmap == [1,2,3,4,4]
                    @test c_45c == 4

                    c_345, c_345c = combine(c_45, [3, 4])
                    @test c_345.indexmap == [1,2,3,3,3]
                    @test c_345c == 3

                    c_345_2, c_345c_2 = combine(nodes, [3,4,5])
                    @test c_345c_2 == 3
                    @test c_345_2.indexmap == [1,2,3,3,3]
                end
                @testset "At the beginning" begin
                    G = zeros(5, 5)
                    nodes = CLENodes(G)

                    c_12, c_12c = combine(nodes, [1, 2])
                    @test length(c_12) == 4
                    @test c_12c == 1
                    @test c_12.indexmap == [1, 1, 2, 3, 4]
                    @test c_12.nodes[1].index == [1,2]
                    @test c_12.nodes[2].index == 3
                    @test c_12.nodes[3].index == 4
                    @test c_12.nodes[4].index == 5

                    c_123, c_123c = combine(c_12, [1, 2])
                    @test length(c_123) == 3
                    @test c_123c == 1
                    @test c_123.indexmap == [1, 1, 1, 2, 3]
                    @test c_123.nodes[1].index == [1,2,3]

                    c_123_2, c_123c_2 = combine(nodes, [1,2,3])
                    @test length(c_123_2) == 3
                    @test c_123c_2 == 1
                    @test c_123_2.indexmap == [1, 1, 1, 2, 3]
                    @test c_123_2.nodes[1].index == [1,2,3]
                end
                @testset "In the middle" begin
                    G = zeros(5, 5)
                    nodes = CLENodes(G)

                    c_23, c_23c = combine(nodes, [2,3])
                    @test length(c_23.nodes) == 4
                    @test c_23c ==2
                    @test c_23.indexmap == [1,2,2,3,4]

                    c_234, c_234c = combine(c_23, [2,3])
                    @test length(c_234.nodes) == 3
                    @test c_234c == 2
                    @test c_234.indexmap == [1,2,2,2,3]

                    c_234_2, c_234c_2 = combine(nodes, [2,3,4])
                    @test length(c_234_2.nodes) == 3
                    @test c_234c_2 == 2
                    @test c_234_2.indexmap == [1,2,2,2,3]
                end
            end
            @testset "Discontinous" begin
                G = zeros(5, 5)
                nodes = CLENodes(G)
                c_24, c_24c = combine(nodes, [2, 4])
                @test c_24c == 2
                @test c_24.indexmap == [1,2,3,2,4]
            end
        end

        @testset "Expanding combined nodes" begin
        end

        @testset "SLP Ch todo: 'Book that flight' example" begin
            using DependencyTrees.GraphParsing: chu_liu_edmonds

            scores = reshape([12, 6, 5, 5, 4, 7, 7, 8, 4], (3, 3))
            graph = DependencyGraph(scores)

            # make sure that I set up the scores matrix correctly
            @test getarc(graph, 0, 1) == 12
            @test getarc(graph, 2, 1) == 6
            @test getarc(graph, 3, 1) == 5

            @test getarc(graph, 0, 2) == getarc(graph, 2, 2) == 4
            @test getarc(graph, 1, 2) == 5
            @test getarc(graph, 3, 2) == 7

            @test getarc(graph, 2, 3) == 8
            # @test getarc(graph, 0, :) == [12, 4, 4]
            # @show chu_liu_edmonds(graph)

            using DependencyTrees.GraphParsing: CLENode
            using DependencyTrees.GraphParsing: greedy_predict, choose_head

            node1, node2, node3 = [CLENode(scores, i) for i=1:3]

            @test choose_head(scores, node1) == ((0,1), 12)
            @test choose_head(scores, node2) == ((3,2), 7)
            @test choose_head(scores, node3) == ((2,3), 8)
            pred1, scores1 = greedy_predict(scores, [node1, node2, node3])
            @test pred1 == [(0,1), (3,2), (2,3)]
            @test scores1 == [12, 7, 8]
            
            heads1 = first.(pred1)
            @test has_cycles(heads1)
            cycles = find_cycles(heads1)
            @test length(cycles) == 1
            cycle = pop!(cycles)
            @test cycle == Set([2,3])

            using DependencyTrees.GraphParsing: CLENodes, combine
            nodes1 = CLENodes(scores)
            nodes2, toexpand = combine(nodes1, cycle)

            using DependencyTrees.GraphParsing: adjust
            scores_adjusted = adjust(scores, nodes1, scores1)
            
            @test getarc(scores_adjusted, 0, 1) == 0
            @test getarc(scores_adjusted, 0, 2) == -3
            @test getarc(scores_adjusted, 0, 3) == -4

            @test getarc(scores_adjusted, 1, 2) == -2
            @test getarc(scores_adjusted, 1, 3) == -1

            @test getarc(scores_adjusted, 2, 1) == -6
            @test getarc(scores_adjusted, 2, 3) == 0

            @test getarc(scores_adjusted, 3, 1) == -7
            @test getarc(scores_adjusted, 3, 2) == 0

            
            @test length(nodes2.nodes) == 2
            cnode = nodes2.nodes[toexpand]
            @test cnode.index == [2,3]
            @test all(i -> nodes2.indexmap[i] == toexpand, cycle)
            
            pred2, scores2 = greedy_predict(scores_adjusted, nodes2)
            heads2 = first.(pred2)
            @test heads2 == [0, 1]
            @test scores2 == [0, -1]
            
            using DependencyTrees.GraphParsing: expand
            expanded = expand(pred1, nodes1, pred2, nodes2, toexpand)
            @test expanded == [(0, 1), (3, 2), (1, 3)]

            using DependencyTrees.GraphParsing: chu_liu_edmonds
            best_arcs, best_score = chu_liu_edmonds(scores)
            @test best_arcs == [(0, 1), (3, 2), (1, 3)]
            @test best_score == 12 + 7 + 7
        end
    end
end
