# tests from nivre 08 "algorithms for deterministic incremental
# dependency parsing"

@testset "Nivre 08" begin
    error_cb(args...) = error("dependency parse error")

    # multi-headed czech sentence from universal dependencies treebank
    # ("Only one of them concerns quality.")
    figure_1_sent = [("Z", "AuxP", 5),      # out-of
                     ("nich", "Atr", 1),    # them
                     ("je", "Pred", 0),     # is
                     ("jen", "AuxZ", 5),    # only
                    ("jedna", "Sb", 3),    # one-FEM-SG
                     ("na", "AuxP", 3),     # to
                     ("kvalitu", "Adv", 6), # quality
                     (".", "AuxK", 0)]      # .

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
        graph = DependencyTree(TypedDependency, figure_2_sent, add_id=true)
        cfg = initconfig(ArcEager(), graph)
        @test stack(cfg) == [0]
        @test buffer(cfg) == 1:9
        for t in [Shift(), LeftArc("NMOD"), Shift(), LeftArc("SUBJ"),
                  RightArc("ROOT"), Shift(), LeftArc("NMOD"), RightArc("OBJ"),
                  RightArc("NMOD"), Shift(), LeftArc("NMOD"), RightArc("PMOD"),
                  Reduce(), Reduce(), Reduce(), RightArc("P")]
            @test !isfinal(cfg)
            @test t == static_oracle(cfg, graph, typed)
            cfg = t(cfg)
        end
        @test isfinal(cfg)
        result = DependencyTree(tokens(cfg))
        @test result == graph
    end

    @testset "Figure 8" begin

        using DependencyTrees: MultipleRootsError, ListBasedNonProjective, NoArc

        @test_throws MultipleRootsError DependencyTree(TypedDependency, figure_1_sent, add_id=true)
        graph = DependencyTree(TypedDependency, figure_1_sent; add_id=true, check_single_head=false)
        words = form.(graph)

        oracle(cfg) = static_oracle(cfg, graph, typed)

        @test !projective_only(ListBasedNonProjective())

        cfg = DependencyTrees.initconfig(ListBasedNonProjective(), TypedDependency, words)
        gold_transitions = [Shift(), RightArc("Atr"), Shift(), NoArc(), NoArc(),
                            RightArc("Pred"), Shift(), Shift(), LeftArc("AuxZ"),
                            RightArc("Sb"), NoArc(), LeftArc("AuxP"), Shift(),
                            NoArc(), NoArc(), RightArc("AuxP"), Shift(),
                            RightArc("Adv"), Shift(), NoArc(), NoArc(), NoArc(),
                            NoArc(), NoArc(), NoArc(), NoArc(), RightArc("AuxK"),
                            Shift()]

        for t in gold_transitions
            @test !isfinal(cfg)
            @test oracle(cfg) == t
            cfg = t(cfg) 
        end
        @test isfinal(cfg)
        result = DependencyTree(cfg.A, check_single_head=false)
        @test result == graph

        o = StaticOracle(ListBasedNonProjective(), transition=typed)
        pairs = DependencyTrees.xys(o, graph)
        @test last.(pairs) == gold_transitions

        c = DependencyTrees.initconfig(ListBasedNonProjective(), graph)
        @test DependencyTrees.deptype(c) == TypedDependency
    end
end
