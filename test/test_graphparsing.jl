@testset "Graph Parsing" begin

    using DependencyTrees.GraphParsing: DependencyGraph, getarc

    @testset "Cycle Detection" begin
        @testset "Tarjan's Algorithm" begin
            using DependencyTrees.GraphParsing: tarjan

            @testset "One Cycle" begin
                @test Set([1, 2]) in tarjan([2, 1])
                @test Set([1, 2, 3]) in tarjan([2, 3, 1])
            end

            @testset "Two Cycles" begin
                cycles = tarjan([2, 1, 4, 3])
                @test Set([1, 2]) in cycles
                @test Set([3, 4]) in cycles
                @test length(cycles) == 2
            end
        end
    end

    @testset "Chu-Liu/Edmonds" begin
        
        graph = DependencyGraph(rand(10, 10))
    end

    @testset "'Book that flight'" begin

        scores = reshape([12, 6, 5, 5, 4, 7, 7, 8, 4], (3, 3))
        graph = DependencyGraph(scores)
        @test getarc(graph, 0, 1) == 12
        # @test getarc(graph, 0, :) == [12, 4, 4]
        
    end

end
