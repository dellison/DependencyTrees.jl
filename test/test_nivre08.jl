using DependencyTrees: shift, leftarc, rightarc
using DependencyTrees: OnlineTrainer

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

        words = first.(figure_2_sent)
        config = DependencyTrees.initconfig(ArcEager(), TypedDependency, first.(figure_2_sent))
        @test config.σ == [0]
        @test config.β == 1:9
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

        oracle = DependencyTrees.static_oracle(ArcEager(), graph)
        config = DependencyTrees.initconfig(ArcEager(), TypedDependency, first.(figure_2_sent))
        gold_transitions = [Shift(),
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
        for t in gold_transitions
            @test oracle(config) == t
            config = t(config)
        end
        graph2 = DependencyTree(config.A)
        @test graph == graph2

        # trainer = OnlineTrainer(StaticOracle(ArcEager{TypedDependency}), oracle, identity, error_cb)
        # train!(trainer, graph)
    end

    @testset "Figure 8" begin

        using DependencyTrees: MultipleRootsError, ListBasedNonProjective
        using DependencyTrees: NoArc
        using DependencyTrees: isfinal

        @test_throws MultipleRootsError DependencyTree(TypedDependency, figure_1_sent, add_id=true)
        graph = DependencyTree(TypedDependency, figure_1_sent; add_id=true, check_single_head=false)
        words = form.(graph)

        oracle = DependencyTrees.static_oracle(ListBasedNonProjective(), graph)

        @test ! DependencyTrees.projective_only(ListBasedNonProjective())

        cfg = DependencyTrees.initconfig(ListBasedNonProjective(), TypedDependency, words)
        gold_transitions = [Shift(),
                            RightArc("Atr"),
                            Shift(),
                            NoArc(),
                            NoArc(),
                            RightArc("Pred"),
                            Shift(),
                            Shift(),
                            LeftArc("AuxZ"),
                            RightArc("Sb"),
                            NoArc(),
                            LeftArc("AuxP"),
                            Shift(),
                            NoArc(),
                            NoArc(),
                            RightArc("AuxP"),
                            Shift(),
                            RightArc("Adv"),
                            Shift(),
                            NoArc(),
                            NoArc(),
                            NoArc(),
                            NoArc(),
                            NoArc(),
                            NoArc(),
                            NoArc(),
                            RightArc("AuxK"),
                            Shift()]
        for t in gold_transitions
            @test !isfinal(cfg)
            t̂ = oracle(cfg)
            @test t̂ == t
            @test t̂(cfg) == t(cfg)
            cfg = t(cfg) 
        end
        @test isfinal(cfg)
        graph2 = DependencyTree(cfg.A, check_single_head=false)
        @test graph2 == graph

        o = StaticOracle(ListBasedNonProjective())
        pairs = DependencyTrees.xys(o, graph)
        @test last.(pairs) == gold_transitions
        trainer = OnlineTrainer(o, oracle, identity, error_cb)
        train!(trainer, graph)

        c = DependencyTrees.initconfig(ListBasedNonProjective(), graph)
        @test DependencyTrees.deptype(c) == TypedDependency
    end
end
