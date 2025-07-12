# tests from sandra kubler, ryan mcdonald, joakim nivre 09 "dependency
# parsing" (https://doi.org/10.2200/S00169ED1V01Y200901HLT002)

@testset "Kübler et al 09" begin
    # @test projective_only(ArcEager())

    @testset "Figure 3.7" begin
        tree = test_sentence("economicnews.conll")
        # oracle = StaticOracle(ArcEager(), arc=typed)
        oracle = Oracle(ArcEager(), static_oracle, typed)

        gold_transitions = [Shift(), LeftArc("ATT"), Shift(), LeftArc("SBJ"),
                            RightArc("PRED"), Shift(), LeftArc("ATT"),
                            RightArc("OBJ"), RightArc("ATT"), Shift(),
                            LeftArc("ATT"), RightArc("PC"), Reduce(),
                            Reduce(), Reduce(), RightArc("PU")]

        cfg = initconfig(ArcEager(), tree)
        
        for t in gold_transitions
            @test !isfinal(cfg)
            @test oracle.oracle_function(cfg, tree, typed) == t
            cfg = t(cfg)
        end
        @test isfinal(cfg)
        result = DependencyTree(cfg)
        @test labeled_accuracy(result, tree) == 1

        # oracle = StaticOracle(ArcEager(), arc=typed)
        oracle = Oracle(ArcEager(), static_oracle, typed)
        # pairs = xys(oracle, tree)
        pairs = oracle(tree)
        @test collect(last.(pairs)) == gold_transitions
        @test collect(oracle(tree)) == collect(pairs)
    end
end
