using DependencyTrees: TreebankReader

@testset "Dynamic Oracle" begin

    error_cb(args...) = nothing
    
    oracle = DynamicOracle(ArcEager())
    
    model(cfg) = nothing
    
    trainer = OnlineTrainer(oracle, model, identity, error_cb)

    sent = [
        ("Economic", "NMOD", 2),  # 1
        ("news", "SUBJ", 3),      # 2
        ("had", "ROOT", 0),       # 3
        ("little", "NMOD", 5),    # 4
        ("effect", "OBJ", 3),     # 5
        ("on", "NMOD", 5),        # 6
        ("financial", "NMOD", 8), # 7
        ("markets", "PMOD", 6),   # 8
        (".", "P", 3),            # 9
    ]

    graph = DependencyTree(TypedDependency, sent, add_id=true)
    DependencyTrees.train!(trainer, graph)

    model = static_oracle(ArcEager(), graph)
    function error_cb(x, ŷ, y)
        @assert false
    end
    trainer = OnlineTrainer(oracle, model, identity, error_cb)
    DependencyTrees.train!(trainer, graph)

    cfg = DependencyTrees.initconfig(oracle.transition_system, graph)
    while !isfinal(cfg)
        pred = model(cfg)
        gold = DependencyTrees.gold_transitions(oracle, cfg, graph)
        zeroc = DependencyTrees.zero_cost_transitions(cfg, graph)
        @test gold == zeroc
        @test pred in gold
        @test any(t -> DependencyTrees.hascost(t, cfg, graph), [Shift(), Reduce(), LeftArc("lol"), RightArc("lol")])
        @test all(t -> DependencyTrees.haszerocost(t, cfg, graph), gold)
        cfg = pred(cfg)
    end

    # make sure this works the same for untyped oracles too
    oracle_ut = DynamicOracle(ArcEager(), transition=DependencyTrees.untyped)
    DependencyTrees.xys(oracle_ut, graph)
    model = static_oracle(ArcEager(), graph, DependencyTrees.untyped)
    cfg = DependencyTrees.initconfig(oracle_ut.transition_system, graph)
    while !isfinal(cfg)
        pred = model(cfg)
        gold = DependencyTrees.gold_transitions(oracle_ut, cfg, graph)
        zeroc = DependencyTrees.zero_cost_transitions(cfg, graph, DependencyTrees.untyped)
        @test gold == zeroc
        @test pred in gold
        @test any(t -> DependencyTrees.hascost(t, cfg, graph), [Shift(), Reduce(), LeftArc(), RightArc()])
        @test all(t -> DependencyTrees.haszerocost(t, cfg, graph), gold)
        cfg = pred(cfg)
    end

    trainer = OnlineTrainer(oracle, x -> nothing, identity, (args...) -> nothing)
    tbfile = joinpath(@__DIR__, "data", "wsj_0001.dp")
    treebank = Treebank{TypedDependency}(tbfile, add_id=true)
    trees = collect(treebank)
    for tree in trees
        DependencyTrees.train!(trainer, tree)
    end

    trainer = OnlineTrainer(oracle, x -> nothing, identity, (args...) -> nothing)
    treebank = Treebank{TypedDependency}(tbfile, add_id=true)
    # DependencyTrees.train!(trainer, treebank)

    @test DependencyTrees.choose_next_amb(1, 1:5) == 1
    @test DependencyTrees.choose_next_exp(0, 1:5, () -> true) == 0
    @test DependencyTrees.choose_next_exp(0, 1:5, () -> false) != 0
    @test DependencyTrees.zero_cost_transitions(cfg, graph) == [Reduce()]

    for (cfg, gold) in DependencyTrees.xys(oracle, graph)
        @test length(gold) >= 1
    end

    @testset "Projectivity" begin
        oracle = DynamicOracle(ArcHybrid())
        tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "nonprojective1.conll"))
        @test length(collect(tb)) == 1
        @test length(DependencyTrees.xys(oracle, tb)) == 0
    end

    @testset "Dynamic Iteration" begin
        oracle = DynamicOracle(ArcHybrid(), transition=DependencyTrees.untyped)
        tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "hybridtests.conll"))

        for tree in treebank
            for (cfg, G) in DependencyTrees.xys(oracle, tree)
                @test cfg isa DependencyTrees.ArcHybridConfig
                for t in G
                    T = typeof(t)
                    @test T <: DependencyTrees.LeftArc || T <: DependencyTrees.RightArc || T <: DependencyTrees.Shift
                end
            end

            for state in DependencyTrees.DynamicGoldSearch(oracle, tree)
                @test state.G ⊆ state.A
                t, next = DependencyTrees.explore(state)
                @test t(state.cfg) == next == DependencyTrees.next_state(state, t)
                @test t in state.A
                @test DependencyTrees.explore(state, t) == (t, next)
            end
        end
    end
end

@testset "Transition Output Spaces" begin
    using DependencyTrees: transition_space, LeftArc, RightArc, NoArc, Reduce, Shift
    
    @test transition_space(ArcEager()) == [LeftArc(), RightArc(), Reduce(), Shift()]
    @test transition_space(ArcEager(), ["a","b"]) == [LeftArc("a"), LeftArc("b"),
                                                      RightArc("a"), RightArc("b"),
                                                      Reduce(), Shift()]

    @test transition_space(ArcHybrid()) == [LeftArc(), RightArc(), Shift()]
    @test transition_space(ArcHybrid(), ["a","b"]) == [LeftArc("a"), LeftArc("b"),
                                                       RightArc("a"), RightArc("b"),
                                                       Shift()]

    @test transition_space(ArcStandard()) == [LeftArc(), RightArc(), Shift()]
    @test transition_space(ArcStandard(), ["a","b"]) == [LeftArc("a"), LeftArc("b"),
                                                         RightArc("a"), RightArc("b"),
                                                         Shift()]

    @test transition_space(ArcSwift(); max_k=2) == [LeftArc(1), LeftArc(2),
                                                    RightArc(1), RightArc(2),
                                                    Shift()]
    ts1 = Set(transition_space(ArcSwift(), ["a","b"]; max_k=2))
    ts2 = Set([LeftArc(1, "a"), LeftArc(2, "a"),
               LeftArc(1, "b"), LeftArc(2, "b"),
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
    using DependencyTrees: AlwaysExplore, NeverExplore, ExplorationPolicy
    always1, never1 = AlwaysExplore(), NeverExplore()
    always2, never2 = ExplorationPolicy(0,1), ExplorationPolicy(0,0)
    for i = 1:10
        @test always1(i) == always2(i) == true
        @test never1(i)  == never2(i)  == false
    end
end
