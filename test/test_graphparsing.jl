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

    @testset "Chu-Liu/Edmonds" begin
        graph = DependencyGraph(rand(10, 10))
    end

    @testset "'Book that flight'" begin
        using DependencyTrees.GraphParsing: chu_liu_edmonds

        scores = reshape([12, 6, 5, 5, 4, 7, 7, 8, 4], (3, 3))
        graph = DependencyGraph(scores)
        @test getarc(graph, 0, 1) == 12
        # @test getarc(graph, 0, :) == [12, 4, 4]
        # @show chu_liu_edmonds(graph)
    end

end
