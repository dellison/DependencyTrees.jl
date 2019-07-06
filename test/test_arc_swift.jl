@testset "Arc-Swift" begin

    # See paper:
    # Qi & Manning 2017: "Arc-swift: A Novel Transition System for Dependency Parsing"
    # https://nlp.stanford.edu/pubs/qi2017arcswift.pdf

    # note that the transition sequences tested here are compared with
    # the arc-swift implementation at https://github.com/qipeng/arc-swift
    
    @test projective_only(ArcSwift())

    chopsticks_tree = test_sentence("chopsticks.conll")
    ketchup_tree = test_sentence("ketchup.conll")

    @testset "Arc Eager Reduce" begin
        oracle = StaticOracle(ArcEager(), arc=typed)
        @test last.(xys(oracle, chopsticks_tree)) ==
            [Shift(), LeftArc("nsubj"), RightArc("root"), RightArc("dobj"), Reduce(),
             Shift(), LeftArc("case"), RightArc("inst"), Reduce(), RightArc(".")]

        @test last.(xys(oracle, ketchup_tree)) ==
            [Shift(), LeftArc("nsubj"), RightArc("root"), RightArc("dobj"),
             RightArc("nmod"), RightArc("case"), Reduce(), Reduce(), Reduce(),
             RightArc(".")]
    end

    @testset "Arc Eager Shift" begin
        oracle = StaticOracle(ArcEager(), static_oracle_prefer_shift, arc=typed)

        @test last.(xys(oracle, chopsticks_tree)) ==
            [Shift(), LeftArc("nsubj"), RightArc("root"), RightArc("dobj"),
             Shift(), LeftArc("case"), Reduce(), RightArc("inst"), Reduce(),
             RightArc(".")]

        @test last.(xys(oracle, ketchup_tree)) ==
            [Shift(), LeftArc("nsubj"), RightArc("root"),
             RightArc("dobj"), RightArc("nmod"), RightArc("case"), 
             Reduce(), Reduce(), Reduce(), RightArc(".")]
    end

    @testset "Arc Swift" begin

        oracle = StaticOracle(ArcSwift(), arc=typed)

        @test last.(xys(oracle, chopsticks_tree)) ==
            [Shift(), LeftArc(1, "nsubj"), RightArc(1, "root"), RightArc(1, "dobj"),
             Shift(), LeftArc(1, "case"), RightArc(2, "inst"), RightArc(2, ".")]

        @test last.(xys(oracle, ketchup_tree)) ==
            [Shift(), LeftArc(1, "nsubj"), RightArc(1, "root"), RightArc(1, "dobj"),
             RightArc(1, "nmod"), RightArc(1, "case"), RightArc(4, ".")]

        for tree in (chopsticks_tree, ketchup_tree)
            c1 = initconfig(ArcSwift(), CoNLLU, [t.form for t in tree])
            c2 = initconfig(ArcSwift(), tree)
            @test stack(c1) == stack(c2)
            @test buffer(c1) == buffer(c2)
            @test [t.form for t in c1.A] == [t.form for t in c2.A]
            @test startswith(showstr(c1), "ArcSwiftConfig")
        end
    end

end
