@testset "Arc-Hybrid" begin

    tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "english.conllu"))
    oracle = StaticOracle(ArcHybrid{CoNLLU})
    trees = collect(tb)
    @test length(trees) == 2
    @test length.(trees) == [7, 19]
end
