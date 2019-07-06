@testset "Nivre 08" begin

    # See paper:
    # Nivre, 2008: "Algorithms for Deterministic Incremental Dependency Parsing"
    # https://www.aclweb.org/anthology/J08-4003.pdf

    tree_fig1, tree_fig2 = test_treebank("nivre08.conll")

    @testset "Figure 6" begin
        # arc-eager parse for "economic news had little effect on financial markets"
        table = [
            # Transition      Stack        Buffer
            (Shift(),         [0,1],       2:9),
            (LeftArc("NMOD"), [0],         2:9),
            (Shift(),         [0,2],       3:9),
            (LeftArc("SUBJ"), [0],         3:9),
            (RightArc("ROOT"),[0,3],       4:9),
            (Shift(),         [0,3,4],     5:9),
            (LeftArc("NMOD"), [0,3],       5:9),
            (RightArc("OBJ"), [0,3,5],     6:9),
            (RightArc("NMOD"),[0,3,5,6],   7:9),
            (Shift(),         [0,3,5,6,7], 8:9),
            (LeftArc("NMOD"), [0,3,5,6],   8:9),
            (RightArc("PMOD"),[0,3,5,6,8], [9]),
            (Reduce(),        [0,3,5,6],   [9]),
            (Reduce(),        [0,3,5],     [9]),
            (Reduce(),        [0,3],       [9]),
            (RightArc("P"),   [0,3,9],     [])]

        cfg = initconfig(ArcEager(), tree_fig2)
        o = cfg -> static_oracle(cfg, tree_fig2, typed)
        @test stack(cfg) == [0]
        @test buffer(cfg) == 1:9
        for (t, stk, buf) in table
            @test !isfinal(cfg)
            @test t == o(cfg)
            cfg = t(cfg)
            @test stack(cfg) == stk
            @test buffer(cfg) == buf
        end
        @test isfinal(cfg)
        result = DependencyTree(tokens(cfg))
        @test result == tree_fig2
    end

    @testset "Figure 8" begin
        @test !projective_only(ListBasedNonProjective())
        table = [
            # Transition        L1       L2     buffer
            (Shift(),           [0,1],   [],    2:8),
            (RightArc("Atr"),   [0],     [1],   2:8),
            (Shift(),           [0,1,2], [],    3:8),
            (NoArc(),           [0,1],   [2],   3:8),
            (NoArc(),           [0],     [1,2], 3:8),
            (RightArc("Pred"),  [],      0:2,   3:8),
            (Shift(),           0:3,     [],    4:8),
            (Shift(),           0:4,     [],    5:8),
            (LeftArc("AuxZ"),   0:3,     [4],   5:8),
            (RightArc("Sb"),    0:2,     3:4,   5:8),
            (NoArc(),           0:1,     2:4,   5:8),
            (LeftArc("AuxP"),   [0],     1:4,   5:8),
            (Shift(),           0:5,     [],    6:8),
            (NoArc(),           0:4,     [5],   6:8),
            (NoArc(),           0:3,     4:5,   6:8),
            (RightArc("AuxP"),  0:2,     3:5,   6:8),
            (Shift(),           0:6,     [],    7:8),
            (RightArc("Adv"),   0:5,     [6],   7:8),
            (Shift(),           0:7,     [],    [8]),
            (NoArc(),           0:6,     [7],   [8]),
            (NoArc(),           0:5,     6:7,   [8]),
            (NoArc(),           0:4,     5:7,   [8]),
            (NoArc(),           0:3,     4:7,   [8]),
            (NoArc(),           0:2,     3:7,   [8]),
            (NoArc(),           0:1,     2:7,   [8]),
            (NoArc(),           [0],     1:7,   [8]),
            (RightArc("AuxK"),  [],      0:7,   [8]),
            (Shift(),           0:8,     [],    [])]

        o(cfg) = static_oracle(cfg, tree_fig1, typed)
        cfg = initconfig(ListBasedNonProjective(), tree_fig1)
        for (t, l1, l2, buf) in table
            @test !isfinal(cfg)
            @test o(cfg) == t
            cfg = t(cfg) 
            @test cfg.λ1 == l1
            @test cfg.λ2 == l2
            @test buffer(cfg) == buf
        end
        @test isfinal(cfg)
        @test replace(showstr(cfg), r"\s+"=>"") ==
            """ListBasedNonProjectiveConfig([0,1,2,3,4,5,6,7,8],[],[])
             1	Z	5
             2	nich	1
             3	je	0
             4	jen	5
             5	jedna	3
             6	na	3
             7	kvalitu	6
             8	.	0""" |> x->replace(x, r"\s"=>"")

        result = DependencyTree(cfg.A, check_single_head=false)
        @test result == tree_fig1

        oracle = StaticOracle(ListBasedNonProjective(), arc=typed)
        pairs = DependencyTrees.xys(oracle, tree_fig1)
        @test last.(pairs) == first.(table)

        cfg1 = initconfig(ListBasedNonProjective(), CoNLLU, [w.form for w in tree_fig1])
        cfg2 = initconfig(ListBasedNonProjective(), tree_fig1)
        @test cfg1 != cfg2 # cfg2 knows about the gold labels, cfg1 doesn't
        @test cfg1.λ1 == cfg2.λ1 && cfg1.λ2 == cfg2.λ2 && cfg1.β == cfg2.β
        @test [token(cfg, 1)] == tokens(cfg, [1])
    end
end
