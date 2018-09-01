using DependencyTrees, Test

using DependencyTrees: ArcEagerConfig, shift, leftarc, rightarc

# tests from nivre 08 "algorithms for deterministic incremental
# dependency parsing"

@testset "Nivre 08" begin

    # multi-headed czech sentence from universal dependencies treebank
    # ("Only one of them concerns quality.")
    figure_1_sent = [("Z", "AuxP", 5),   # out-of
                     ("nich", "Atr", 1), # them
                     ("je", "Pred", 0),  # is
                     ("jen", "AuxZ", 5), # only
                     ("jedna", "Sb", 3), # one-FEM-SG
                     ("na", "AuxP", 3),  # to
                     ("kvalitu", "Adv", 6),    # quality
                     (".", "AuxK", 0)]   # .

    figure_2_sent = [
        ("Economic", "NMOD", 2),
        ("news", "SUBJ", 3),
        ("had", "ROOT", 0),
        ("little", "NMOD", 5),
        ("effect", "OBJ", 3),
        ("on", "NMOD", 5),
        ("financial", "NMOD", 8),
        ("markets", "PMOD", 6),
        (".", "P", 3),
    ]

    @testset "Figure 6" begin
        graph = DependencyGraph(TypedDependency, figure_2_sent)

        config = ArcEagerConfig{TypedDependency}(first.(figure_2_sent))
        @test config.stack == [0]
        @test config.word_buffer == 1:9
        config = shift(config)
        config = leftarc(config, "NMOD")
        config = shift(config)
        config = leftarc(config, "SUBJ")
        config = rightarc(config, "ROOT")
        config = shift(config)
        config = leftarc(config, "NMOD")
        config = rightarc(config, "OBJ")
        config = rightarc(config, "NMOD")
        config = shift(config)
        config = leftarc(config, "NMOD")
        config = rightarc(config, "PMOD")
        config = reduce(config)
        config = reduce(config)
        config = reduce(config)
        config = rightarc(config, "P")
        @test isfinal(config)

        oracle = DependencyTrees.static_oracle(ArcEagerConfig, graph)
        config = ArcEagerConfig{TypedDependency}(first.(figure_2_sent))
        for t in [Shift(),
                  LeftArc("NMOD"),
                  Shift(),
                  LeftArc("SUBJ"),
                  RightArc("ROOT"),
                  Shift(),
                  LeftArc("NMOD"),
                  RightArc("OBJ"),
                  RightArc("NMOD"),
                  Shift(),
                  LeftArc("NMOD"),
                  RightArc("PMOD"),
                  Reduce(),
                  Reduce(),
                  Reduce(),
                  RightArc("P")]
            @test oracle(config) == t
            config = t(config)
        end
        graph2 = DependencyGraph(config.relations)
        @test graph == graph2
    end

    @testset "Figure 8" begin

        using DependencyTrees: MultipleRootsError

        @test_throws MultipleRootsError DependencyGraph(TypedDependency, figure_1_sent)
        graph = DependencyGraph(TypedDependency, figure_1_sent; check_single_head=false)
    end
end
