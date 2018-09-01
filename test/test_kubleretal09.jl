using DependencyTrees, Test

using DependencyTrees: ArcEagerConfig, shift, leftarc, rightarc

# tests from sandra kubler, ryan mcdonald, joakim nivre 09 "dependency
# parsing" (https://doi.org/10.2200/S00169ED1V01Y200901HLT002)

@testset "Kübler et al 09" begin

    fig_1_1 = [
        ("Economic", "ATT", 2),
        ("news", "SBJ", 3),
        ("had", "PRED", 0),
        ("little", "ATT", 5),
        ("effect", "OBJ", 3),
        ("on", "ATT", 5),
        ("financial", "ATT", 8),
        ("markets", "PC", 6),
        (".", "PU", 3),
    ]

    graph = DependencyGraph(TypedDependency, fig_1_1)
    @test length(graph) == length(fig_1_1)

    @testset "Figure 3.7" begin
        sent = first.(fig_1_1)

        w2id = Dict(word => id for (id, word) in enumerate(sent))

        graph = DependencyGraph(TypedDependency, fig_1_1)

        oracle = DependencyTrees.static_oracle(ArcEagerConfig, graph)

        config = ArcEagerConfig{TypedDependency}(sent)
        @test config.stack == [0] && config.word_buffer == 1:9

        config = shift(config)
        config = leftarc(config, "ATT")
        config = shift(config) 
        config = leftarc(config, "SBJ")
        config = rightarc(config, "PRED")
        config = shift(config) 
        config = leftarc(config, "ATT")
        config = rightarc(config, "OBJ")
        config = rightarc(config, "ATT")
        config = shift(config) 
        config = leftarc(config, "ATT")
        config = rightarc(config, "PC")
        config = reduce(config) 
        config = reduce(config) 
        config = reduce(config) 
        config = rightarc(config, "PU")
        @test isfinal(config)

        config = ArcEagerConfig{TypedDependency}(sent)
        oracle_configs = [config]
        for t in [Shift()
                  LeftArc("ATT")
                  Shift()
                  LeftArc("SBJ")
                  RightArc("PRED")
                  Shift()
                  LeftArc("ATT")
                  RightArc("OBJ")
                  RightArc("ATT")
                  Shift()
                  LeftArc("ATT")
                  RightArc("PC")
                  Reduce()
                  Reduce()
                  Reduce()
                  RightArc("PU")]
            @test oracle(config) == t
            config = t(config)
        end
        graph2 = DependencyGraph(config.relations)
        @test graph == graph2
    end
end
