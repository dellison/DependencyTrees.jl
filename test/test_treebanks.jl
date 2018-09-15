@testset "Treebanks" begin
    using DependencyTrees: TreebankReader

    datadir = joinpath(@__DIR__, "data")

    @testset "Typed" begin
        T = TypedDependency
        tb1 = TreebankReader{T}(joinpath(datadir, "wsj_0001.dp"), add_id=true)
        tb2 = TreebankReader{T}(joinpath(datadir, "wsj_0001.ids.dp"), add_id=false)

        @test collect(tb1) == collect(tb2)
    end

    @testset "Untyped" begin
        T = UntypedDependency
        tb1 = TreebankReader{T}(joinpath(datadir, "wsj_0001.untyped.dp"), add_id=true)
        tb2 = TreebankReader{T}(joinpath(datadir, "wsj_0001.untyped.ids.dp"), add_id=false)

        @test collect(tb1) == collect(tb2)
    end

    @testset "MWTs" begin
        using DependencyTrees: CoNLLU
        tree = collect(TreebankReader{CoNLLU}(joinpath(datadir, "multiwordtoken.conllu")))[1]
        @test length(tree) == 24
        @test length(tree.mwts) == 1
        @test length(tree.emptytokens) == 0
    end


    @testset "Empty Tokens" begin
        using DependencyTrees: CoNLLU
        tree = collect(TreebankReader{CoNLLU}(joinpath(datadir, "emptytokens.conllu")))[1]
        @test length(tree) == 6
        @test length(tree.mwts) == 0
        @test length(tree.emptytokens) == 1
    end
end
