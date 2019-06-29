@testset "Arc-Swift" begin

    @test projective_only(ArcSwift())

    gold1 = test_sentence("chopsticks.conll")
    gold2 = test_sentence("ketchup.conll")

    @testset "Arc Eager Reduce" begin
        oracle = StaticOracle(ArcEager(), transition=typed)
        (gold_cfgs1, gold_ts1) = zip(xys(oracle, gold1)...)
        @test gold_ts1 == (Shift(), LeftArc("nsubj"), RightArc("root"),
                           RightArc("dobj"), Reduce(), Shift(), LeftArc("case"),
                           RightArc("inst"), Reduce(), RightArc("."))

        (gold_cfgs2, gold_ts2) = zip(xys(oracle, gold2)...)
        @test gold_ts2 == (Shift(), LeftArc("nsubj"), RightArc("root"),
                           RightArc("dobj"), RightArc("nmod"), RightArc("case"), 
                           Reduce(), Reduce(), Reduce(), RightArc("."))
    end

    @testset "Arc Eager Shift" begin
        oracle = StaticOracle(ArcEager(), static_oracle_prefer_shift, transition=typed)
        (gold_cfgs1, gold_ts1) = zip(xys(oracle, gold1)...)

        gold_ts1 = [Shift(), LeftArc("nsubj"), RightArc("root"),
                    RightArc("dobj"), Shift(), LeftArc("case"),
                    Reduce(), RightArc("inst"), Reduce(), RightArc(".")]
        @test collect(gold_ts1) == gold_ts1

        (gold_cfgs2, gold_ts2) = zip(xys(oracle, gold2)...)

        gold_ts2 = [Shift(), LeftArc("nsubj"), RightArc("root"),
                    RightArc("dobj"), RightArc("nmod"), RightArc("case"), 
                    Reduce(), Reduce(), Reduce(), RightArc(".")]
        @test collect(gold_ts2) == gold_ts2
    end

    @testset "Arc Swift" begin

        oracle = StaticOracle(ArcSwift(), transition=typed)

        (gold_cfgs1, gold_ts1) = zip(xys(oracle, gold1)...)
        for (i, (cfg, t)) in enumerate(zip(gold_cfgs1, gold_ts1))
            if i < length(gold_cfgs1)
                @test t(cfg) == gold_cfgs1[i+1]
            else
                @test isfinal(t(cfg))
            end
        end
        @test collect(gold_ts1) == [Shift(), LeftArc(1, "nsubj"), RightArc(1, "root"),
                                    RightArc(1, "dobj"), Shift(), LeftArc(1, "case"),
                                    RightArc(2, "inst"), RightArc(2, ".")]

        (gold_cfgs2, gold_ts2) = zip(xys(oracle, gold2)...)
        for (i, (cfg, t)) in enumerate(zip(gold_cfgs2, gold_ts2))
            if i < length(gold_cfgs2)
                @test t(cfg) == gold_cfgs2[i+1]
            else
                @test isfinal(t(cfg))
            end
        end
        @test collect(gold_ts2) == [Shift(), LeftArc(1, "nsubj"), RightArc(1, "root"),
                                    RightArc(1, "dobj"), RightArc(1, "nmod"),
                                    RightArc(1, "case"), RightArc(4, ".")]

    end

    c1 = initconfig(ArcSwift(), CoNLLU, [t.form for t in gold1])
    c2 = initconfig(ArcSwift(), gold1)
    @test [t.form for t in c1.A] == [t.form for t in c2.A]
end
