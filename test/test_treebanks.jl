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

    @testset "CoNLLU Multiword Tokens" begin
        using DependencyTrees: CoNLLU
        tree = collect(TreebankReader{CoNLLU}(joinpath(datadir, "multiwordtoken.conllu")))[1]
        @test length(tree) == 24
        @test length(tree.mwts) == 1
        @test length(tree.emptytokens) == 0
    end


    @testset "CoNLLU Empty Tokens" begin
        using DependencyTrees: CoNLLU
        tree = collect(TreebankReader{CoNLLU}(joinpath(datadir, "emptytokens.conllu")))[1]
        @test length(tree) == 6
        @test length(tree.mwts) == 0
        @test length(tree.emptytokens) == 1
    end

    @testset "Treebanks" begin
        files = [joinpath(datadir, file) for file in readdir(datadir)
                 if endswith(file, ".conllu")]
        @test length(files) == 3

        treebank = Treebank{CoNLLU}(files)
        trees = collect(treebank)
        @test length(trees) == 4

        treebank2 = Treebank{CoNLLU}(datadir, pattern=r".conllu$")
        trees2 = collect(treebank2)
        @test length(trees2) == 4
        @test trees2 == trees

        for TS in (ArcEager, ArcHybrid, ArcStandard, ArcSwift)
            oracle = StaticOracle(TS{CoNLLU})
            @test xys(oracle, trees) == xys(oracle, trees2)
        end

        @testset "Training" begin
            tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "hybridtests.conll"))

            for TS in (ArcEager, ArcStandard, ArcHybrid, ArcSwift, ListBasedNonProjective)
                oracle = StaticOracle(TS{CoNLLU})
                model(x) = nothing
                update = function (x, pred, gold)
                    @test typeof(x) <: TS
                end
                trainer = OnlineTrainer(oracle, model, identity, update)

                train!(trainer, tb, epochs=1)
            end

        end
    end
end
