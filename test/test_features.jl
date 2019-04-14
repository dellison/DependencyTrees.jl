@testset begin "Features"

    using DependencyTrees: si, bi, s, s0, s1, s2, s3, stack,
                           b, b0, b1, b2, b3, buffer,
                           leftmostdep, rightmostdep,
                           leftdeps, rightdeps,
                           root, noval, token, tokens, xys

    tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "hybridtests.conll"))
    t1 = first(tb)

    for TS in (ArcEager, ArcStandard, ArcHybrid, ArcSwift)
        oracle = StaticOracle(TS())

        cfg = first(first(collect(xys(oracle, t1))))

        @test si(cfg, 0) == s0(cfg) == s(cfg)
        @test bi(cfg, 1) == b(cfg) == b0(cfg)
        @test s1(cfg) == s2(cfg) == s3(cfg) == noval(CoNLLU)
        @test b1(cfg).id == 2
        @test b2(cfg).id == 3
        @test b3(cfg).id == 4
        @test bi(cfg, 100) == noval(CoNLLU)
        @test stack(cfg) == [0]
        @test buffer(cfg) == 1:6
        # no transitions yet
        @test leftmostdep(cfg,0) == rightmostdep(cfg,0) == noval(CoNLLU)
        @test leftmostdep(cfg, root(CoNLLU)) == noval(CoNLLU)
        @test rightmostdep(cfg, root(CoNLLU)) == noval(CoNLLU)

        for i=1:3
            cfg = DependencyTrees.Shift()(cfg)
            @test token(cfg, i).id == i
        end
        @test [id(t) for t in tokens(cfg)] == 1:6
        @test [id(t) for t in tokens(cfg, [1,2,3])] == 1:3
        @test token(cfg, 0)  == root(CoNLLU)
        @test token(cfg, -1) == noval(CoNLLU)

        @test si(cfg, 0) == s0(cfg) == s(cfg)
        @test bi(cfg, 1) == b(cfg) == b0(cfg)
        @test stack(cfg) == 0:3
        @test buffer(cfg) == 4:6
        @test leftmostdep(cfg,0) == rightmostdep(cfg,0) == noval(CoNLLU)

        @test leftdeps(cfg, 0) == rightdeps(cfg, 0) == []
        @test leftdeps(cfg, root(CoNLLU)) == rightdeps(cfg, root(CoNLLU)) == []

        @test leftdeps(cfg, 0) == rightdeps(cfg, 0) == []

        cfg, t = last(collect(DependencyTrees.xys(oracle, first(tb))))
        cfg = t(cfg)
        @test isfinal(cfg)
        @test leftmostdep(cfg, 0) == noval(CoNLLU)
        @test rightmostdep(cfg, 0) == cfg.A[2]
        @test leftmostdep(cfg, cfg.A[2]).form == "I"
    end

    oracle = StaticOracle(ListBasedNonProjective())
    for (cfg, t) in xys(oracle, t1)
        @test token(cfg, 0) == root(CoNLLU)
        @test [id(t) for t in tokens(cfg)] == 1:6
        @test [id(t) for t in tokens(cfg, [1,2,3])] == 1:3
        @test token(cfg, 0)  == root(CoNLLU)
        @test token(cfg, -1) == noval(CoNLLU)
    end
end
