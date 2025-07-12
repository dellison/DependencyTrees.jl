@testset "Dynamic Oracles" begin

    oracle = Oracle(ArcEager(), dynamic_oracle, typed)
    graph = first(Treebank("data/economicnews.conll", conllu))

    model = cfg -> static_oracle(cfg, graph, typed)

    cfg = initconfig(oracle, graph)
    nocost(t, cfg) = DependencyTrees.TransitionParsing.cost(t, cfg, graph) == 0
    while !isfinal(cfg)
        pred = model(cfg)
        G = oracle(cfg, graph)
        @test pred in G
        @test all(t -> nocost(t, cfg), G)
        cfg = pred(cfg)
    end

    # make sure this works the same for untyped oracles too
    oracle = Oracle(ArcEager(), dynamic_oracle, untyped)
    model = cfg -> static_oracle(cfg, graph, untyped)
    cfg = initconfig(oracle.system, graph)
    while !isfinal(cfg)
        pred = model(cfg)
        G = oracle(cfg, graph)
        @test pred in G
        @test any(t -> !nocost(t, cfg), [Shift(), Reduce(), LeftArc(), RightArc()])
        @test all(t -> nocost(t, cfg), G)
        cfg = pred(cfg)
    end

    tbfile = joinpath(@__DIR__, "data", "wsj_0001.dp")
    parse_tree = text -> begin
        DependencyTree(split(text, "\n"; keepempty=false)) do line
            form, deprel, head = split(line, "\t")
            DependencyTrees.Token(form, parse(Int, head), deprel)
        end
    end
    treebank = Treebank(tbfile, parse_tree)

    for (cfg, gold) in oracle(graph)
        @test length(gold) >= 1
    end

    @testset "Projectivity" begin
        o = Oracle(ArcHybrid(), dynamic_oracle)
        tb = Treebank(joinpath(@__DIR__, "data", "nonprojective1.conll"), DependencyTrees.conllu)
        @test length(collect(tb)) == 1
        @test length(collect(Iterators.flatten(oracle.(tb)))) == 0
        @test sum(length(o(t)) for t in tb) == 0

        for tree in tb
            if !is_projective(tree)
                @test isempty(oracle(tree))
            else
                @test !isempty(oracle(tree))
            end
        end
    end

    @testset "Dynamic Iteration" begin
        oracle = Oracle(ArcHybrid(), dynamic_oracle, untyped)
        policy = NeverExplore()

        # tb = Treebank(joinpath(@__DIR__, "data", "hybridtests.conll"), DependencyTrees.conllu)
        tb = test_treebank("hybridtests.conll", conllu)

        for tree in treebank
            for (cfg, G) in oracle(tree)
                @test cfg isa DependencyTrees.TransitionParsing.ArcHybridConfig
                for t in G
                    T = typeof(t)
                    @test T <: LeftArc || T <: RightArc || T <: Shift
                end
            end

            for (cfg, G) in oracle(tree)
                A = possible_transitions(cfg, tree)
                @test G ⊆ A
                t = policy(cfg, A, G)
                @test t in A
            end

            # explore transition space manually
            gold = oracle(tree)
            cfg = initconfig(oracle, tree)
            while !isfinal(cfg)
                t = TransitionParsing.choose_transition(gold, cfg)
                A = TransitionParsing.possible_transitions(cfg)
                @test t in A
                cfg = t(cfg)
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
    @test showstr(always1) == "AlwaysExplore"
    @test showstr(never1) == "NeverExplore"
    for i = 1:10
        @test always1() == always2() == true
        @test never1()  == never2()  == false
    end

    @testset "Models" begin
        oracle = Oracle(ArcEager(), dynamic_oracle, untyped)
        tree = first(test_treebank("chopsticks.conll"))
        @testset "Always" begin
            policy = AlwaysExplore((cfg, A, G) -> first(A))
            xys = collect(oracle(tree, policy))
        end
        @testset "Never" begin
            policy = NeverExplore((cfg, A, G) -> first(A))
            xys = collect(oracle(tree, policy))
        end
        @testset "Rate" begin
            policy = ExplorationPolicy(0.1, (cfg, A, G) -> first(A))
            xys = collect(oracle(tree, policy))
        end
    end

    @testset "RNG" begin
        using Random
        rng = MersenneTwister(42)
        always = AlwaysExplore(rng)
        never  = NeverExplore(rng)
        sometimes = ExplorationPolicy(0.5, rng)

        tree = test_sentence("economicnews.conll")
        for system in (ArcEager(), ArcHybrid())
            oracle = Oracle(system, dynamic_oracle)
            for policy in (always, never, sometimes)
                for (cfg, G) in oracle(tree, policy)
                    @test length(G) >= 1
                end
            end
        end
    end

end

@testset "Feature Extraction" begin

    function check(oracle, gold_tree)
        for (cfg, G) in oracle(gold_tree)
            stk, buf = stack(cfg), buffer(cfg)
            ts = [buffertoken(cfg, b) for b in buf]
            ts = [stacktoken(cfg, s) for s in stk]
        end
        return true
    end

    treebank = Treebank(joinpath(@__DIR__, "data", "hybridtests.conll"), DependencyTrees.conllu)
    for system in (ArcEager(), ArcHybrid())
        for oracle_fn in (static_oracle, dynamic_oracle)
            oracle = Oracle(system, oracle_fn, untyped)
            @test all(check(oracle, tree) for tree in treebank)
        end
    end
end
