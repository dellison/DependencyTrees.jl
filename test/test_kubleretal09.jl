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

    @test projective_only(ArcEager())

    graph = DependencyTree(TypedDependency, fig_1_1, add_id=true)
    @test length(graph) == length(fig_1_1)

    @testset "Figure 3.7" begin
        o = DT.static_oracle(ArcEager(), graph)
        init = DependencyTrees.initconfig(ArcEager(), TypedDependency, first.(fig_1_1))
        @test init.σ == [0] && init.β == 1:9
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

        cfg = init
        for t in gold_transitions
            @test !isfinal(cfg)
            @test o(cfg) == t
            cfg = t(cfg)
        end
        @test isfinal(cfg)
        graph2 = DependencyTree(cfg.A)
        @test graph == graph2

        oracle = StaticOracle(ArcEager())
        pairs = xys(oracle, graph)
        @test collect(last.(pairs)) == gold_transitions
        @test collect(xys(oracle, [graph])) == collect(pairs)
    end
end
