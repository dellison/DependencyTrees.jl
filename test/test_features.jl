@testset begin "Features"

    using DependencyTrees: si, bi, s, s0, s1, s2, s3, stack,
                           b, b0, b1, b2, b3, buffer,
                           leftmostdep, rightmostdep

    tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "hybridtests.conll"))

    oracle = StaticOracle(ArcHybrid())

    cfg = first(first(collect(DependencyTrees.xys(oracle, first(tb)))))

    @test si(cfg, 0) == s0(cfg) == s(cfg)
    @test bi(cfg, 1) == b(cfg) == b0(cfg)
    @test s1(cfg) == s2(cfg) == s3(cfg) == DependencyTrees.noval(CoNLLU)
    @test b1(cfg).id == 2
    @test b2(cfg).id == 3
    @test b3(cfg).id == 4
    @test bi(cfg, 100) == DependencyTrees.noval(CoNLLU)
    @test stack(cfg) == [0]
    @test buffer(cfg) == 1:6
    # no transitions yet
    @test leftmostdep(cfg,0) == rightmostdep(cfg,0) == DependencyTrees.noval(CoNLLU)
    @test leftmostdep(cfg, DependencyTrees.root(CoNLLU)) == DependencyTrees.noval(CoNLLU)
    @test rightmostdep(cfg, DependencyTrees.root(CoNLLU)) == DependencyTrees.noval(CoNLLU)

    for i=1:3
        cfg = DependencyTrees.Shift()(cfg)
    end

    @test si(cfg, 0) == s0(cfg) == s(cfg)
    @test bi(cfg, 1) == b(cfg) == b0(cfg)
    @test stack(cfg) == 0:3
    @test buffer(cfg) == 4:6
    @test leftmostdep(cfg,0) == rightmostdep(cfg,0) == DependencyTrees.noval(CoNLLU)

    cfg, t = last(collect(DependencyTrees.xys(oracle, first(tb))))
    cfg = t(cfg)
    @test isfinal(cfg)
    @test leftmostdep(cfg, 0) == DependencyTrees.noval(CoNLLU)
    @test rightmostdep(cfg, 0) == cfg.A[2]
end
