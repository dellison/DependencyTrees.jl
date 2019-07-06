@testset "Dynamic Oracles" begin

    error_cb(args...) = nothing
    
    oracle = DynamicOracle(ArcEager(), arc=typed)
    
    model(cfg) = nothing
    
    graph = test_sentence("economicnews.conll")

    model(cfg) = static_oracle(cfg, graph, typed)
    function error_cb(x, ŷ, y)
        @assert false
    end

    cfg = initconfig(oracle.system, graph)
    nocost(t, cfg) = DependencyTrees.cost(t, cfg, graph) == 0
    while !isfinal(cfg)
        pred = model(cfg)
        G = gold_transitions(oracle, cfg, graph)
        @test pred in G
        @test all(t -> nocost(t, cfg), G)
        cfg = pred(cfg)
    end

    # make sure this works the same for untyped oracles too
    oracle_ut = DynamicOracle(ArcEager(), arc=untyped)
    DependencyTrees.xys(oracle_ut, graph)
    model(cfg) = static_oracle(cfg, graph, untyped)
    cfg = initconfig(oracle_ut.system, graph)
    while !isfinal(cfg)
        pred = model(cfg)
        G = gold_transitions(oracle_ut, cfg, graph)
        @test pred in G
        @test any(t -> !nocost(t, cfg), [Shift(), Reduce(), LeftArc(), RightArc()])
        @test all(t -> nocost(t, cfg), G)
        cfg = pred(cfg)
    end

    tbfile = joinpath(@__DIR__, "data", "wsj_0001.dp")
    treebank = Treebank{TypedDependency}(tbfile, add_id=true)
    trees = collect(treebank)
    for tree in trees
    end

    for (cfg, gold) in xys(oracle, graph)
        @test length(gold) >= 1
    end

    @testset "Projectivity" begin
        oracle = DynamicOracle(ArcHybrid())
        tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "nonprojective1.conll"))
        @test length(collect(tb)) == 1
        @test length(collect(DependencyTrees.xys(oracle, tb))) == 0
    end

    @testset "Dynamic Iteration" begin
        oracle = DynamicOracle(ArcHybrid(), arc=untyped)
        policy = NeverExplore()

        tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "hybridtests.conll"))

        for tree in treebank
            for (cfg, G) in xys(oracle, tree)
                @test cfg isa DT.ArcHybridConfig
                for t in G
                    T = typeof(t)
                    @test T <: LeftArc || T <: RightArc || T <: Shift
                end
            end

            for state in oracle(tree)
                @test state.G ⊆ state.A
                t = policy(state)
                @test t in state.A
            end
        end
    end
end

@testset "Transition Output Spaces" begin
    @test transition_space(ArcEager()) == [LeftArc(), RightArc(), Reduce(), Shift()]
    @test transition_space(ArcEager(), ["a","b"]) == [LeftArc("a"),  LeftArc("b"),
                                                      RightArc("a"), RightArc("b"),
                                                      Reduce(), Shift()]

    @test transition_space(ArcHybrid()) == [LeftArc(), RightArc(), Shift()]
    @test transition_space(ArcHybrid(), ["a","b"]) == [LeftArc("a"),  LeftArc("b"),
                                                       RightArc("a"), RightArc("b"),
                                                       Shift()]

    @test transition_space(ArcStandard()) == [LeftArc(), RightArc(), Shift()]
    @test transition_space(ArcStandard(), ["a","b"]) == [LeftArc("a"),  LeftArc("b"),
                                                         RightArc("a"), RightArc("b"),
                                                         Shift()]

    @test transition_space(ArcSwift(); max_k=2) == [LeftArc(1),  LeftArc(2),
                                                    RightArc(1), RightArc(2),
                                                    Shift()]
    ts1 = Set(transition_space(ArcSwift(), ["a","b"]; max_k=2))
    ts2 = Set([LeftArc(1, "a"),  LeftArc(2, "a"),
               LeftArc(1, "b"),  LeftArc(2, "b"),
               RightArc(1, "a"), RightArc(2, "a"),
               RightArc(1, "b"), RightArc(2, "b"),
               Shift()])
    @test  ts1 == ts2

    @test transition_space(ListBasedNonProjective()) == [LeftArc(), RightArc(), NoArc(), Shift()]
    @test transition_space(ListBasedNonProjective(), ["a","b"]) == [LeftArc("a"), LeftArc("b"),
                                                                    RightArc("a"), RightArc("b"),
                                                                    NoArc(), Shift()]
end

@testset "Exploration Policies" begin
    always1, never1 = AlwaysExplore(), NeverExplore()
    always2, never2 = ExplorationPolicy(1), ExplorationPolicy(0)
    for i = 1:10
        @test always1() == always2() == true
        @test never1()  == never2()  == false
    end
end
