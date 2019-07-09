@testset "Arc-Hybrid" begin

    @test showstr(LeftArc()) == "LeftArc()"
    @test showstr(LeftArc("mod")) == "LeftArc(mod)"
    for t in [LeftArc(), RightArc(), Shift()]
        @test isempty(DependencyTrees.args(t)) && isempty(DependencyTrees.kwargs(t))
    end
    for t in [LeftArc("label"), RightArc("label")]
        @test !isempty(DependencyTrees.args(t)) && isempty(DependencyTrees.kwargs(t))
    end

    AH = ArcHybrid()

    tb = test_treebank("hybridtests.conll")

    trees = collect(tb)
    @test length(trees) == 4
    @test length.(trees) == [6, 6, 9, 18]

    @test DT.projective_only(ArcHybrid())

    t1 = first(trees)
    c1,c2 = initconfig(AH, CoNLLU, [t.form for t in t1]), initconfig(AH, t1)
    @test [t.form for t in tokens(c1)] == [t.form for t in tokens(c2)]

    @testset "Static Oracle" begin
        oracle = StaticOracle(AH, arc=typed)
        model(x) = nothing
        errorcb(x, ŷ, y) = nothing

        function test_oracle(gold)
            gold_xys = collect(xys(oracle, gold))
            cfg, t = last(gold_xys)
            cfg = t(cfg)
            graph = DependencyTree(tokens(cfg))
            @test all(enumerate(graph)) do (i, token)
                g = gold[i]
                token.form == g.form && token.deprel == g.deprel && token.head == g.head
            end
        end

        for tree in tb
            test_oracle(tree)
        end

        s1, s2, s3, s4 = collect(tb)

        @test last.(xys(oracle, s1)) == [Shift(), LeftArc("nsubj"), Shift(),
                                         Shift(), RightArc("dobj"), Shift(),
                                         LeftArc("case"), Shift(), RightArc("inst"),
                                         Shift(), RightArc("pu"), RightArc("root")]

        @test last.(xys(oracle, s2)) == [Shift(), LeftArc("nsubj"), Shift(), Shift(),
                                         Shift(), Shift(), RightArc("case"),
                                         RightArc("nmod"), RightArc("dobj"), Shift(),
                                         RightArc("pu"), RightArc("root")]

        @test last.(xys(oracle, s3)) == [Shift(), LeftArc("att"), Shift(), LeftArc("sbj"),
                                         Shift(), Shift(), LeftArc("att"), Shift(), Shift(),
                                         Shift(), LeftArc("att"), Shift(), RightArc("pc"),
                                         RightArc("att"), RightArc("obj"), Shift(),
                                         RightArc("pu"), RightArc("pred")]

        @test last.(xys(oracle, s4)) == [Shift(), LeftArc("NNP"), Shift(), Shift(),
                                         RightArc("P"), Shift(), LeftArc("CD"), Shift(),
                                         LeftArc("NNS"), Shift(), RightArc("JJ"), Shift(),
                                         RightArc("PU"), LeftArc("NNP"), Shift(), Shift(),
                                         Shift(), LeftArc("DT"), Shift(), RightArc("NN"),
                                         Shift(), Shift(), Shift(), LeftArc("JJ"),
                                         LeftArc("DT"), Shift(), RightArc("NN"),
                                         RightArc("IN"), Shift(), Shift(), RightArc("CD"),
                                         RightArc("NNP"), RightArc("VB"), Shift(),
                                         RightArc("P"), RightArc("MD")]
    end

    @testset "Dynamic Oracle" begin
        TS = Union{LeftArc, RightArc, Shift}
        oracle = DynamicOracle(ArcHybrid(), arc=typed)
        model(x) = Shift()
        function errorcb(x, ŷ, y)
            @test typeof(x) <: DT.Parse.ArcHybridConfig && typeof(y) <: TS
            @test ŷ == Shift()
            @test typeof(y) <: Union{Shift, LeftArc, RightArc}
        end
    end

    @test showstr(Shift()) == "Shift()"
    @test showstr(Reduce()) == "Reduce()"
    @test showstr(LeftArc()) == "LeftArc()"
    @test showstr(LeftArc("nsubj")) == "LeftArc(nsubj)"
    @test showstr(RightArc()) == "RightArc()"
    @test showstr(RightArc("nsubj")) == "RightArc(nsubj)"
    @test showstr(LeftArc("dobj", upos="NN")) == "LeftArc(dobj; upos=NN)"
end
