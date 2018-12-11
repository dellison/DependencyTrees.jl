using DependencyTrees, Test

using DependencyTrees: ArcEager, shift, leftarc, rightarc
using DependencyTrees: LeftArc, RightArc, Shift, Reduce
using DependencyTrees: StaticOracle, train!, xys

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

    graph = DependencyGraph(TypedDependency, fig_1_1, add_id=true)
    @test length(graph) == length(fig_1_1)

    @testset "Figure 3.7" begin
        sent = first.(fig_1_1)

        graph = DependencyGraph(TypedDependency, fig_1_1, add_id=true)

        oracle = DependencyTrees.static_oracle(ArcEager, graph)

        init = ArcEager{TypedDependency}(sent)
        @test init.σ == [0] && init.β == 1:9

        config = ArcEager{TypedDependency}(sent)

        gold_transitions = [Shift()
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

        for t in gold_transitions
            @test !isfinal(config)
            @test oracle(config) == t
            config = t(config)
        end
        @test isfinal(config)
        graph2 = DependencyGraph(config.A)
        @test graph == graph2

        graph3 = DependencyTrees.parse(ArcEager{TypedDependency}, sent, oracle)
        @test graph3 == graph2

        oracle = StaticOracle(ArcEager{TypedDependency})
        pairs = xys(oracle, graph)
        @test collect(last.(pairs)) == gold_transitions
        @test collect(xys(oracle, [graph])) == collect(pairs)

        model = static_oracle(oracle.config, graph) # perfect model for this sentence)
        trainer = OnlineTrainer(oracle, model, identity, (x, ŷ, y) -> error("oracle was wrong"))
        train!(trainer, graph)
    end
end
