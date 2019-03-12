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

        @test_throws Exception Treebank{CoNLLU}("not a corpus")

        treebank = Treebank{CoNLLU}(files)
        trees = collect(treebank)
        @test length(treebank) == length(trees) == 4
        @test DependencyTrees.deptype(treebank) == CoNLLU

        treebank2 = Treebank{CoNLLU}(datadir, pattern=r".conllu$")
        trees2 = collect(treebank2)
        @test length(trees2) == 4
        @test trees2 == trees

        for TS in (ArcEager, ArcHybrid, ArcStandard, ArcSwift)
            oracle = StaticOracle(TS())
            @test xys(oracle, trees) == xys(oracle, trees2)
        end

        np = joinpath(datadir, "nonprojective.conll")
        ptreebank = Treebank{CoNLLU}(np, remove_nonprojective=true)
        nptreebank = Treebank{CoNLLU}(np, remove_nonprojective=false)
        @test length(collect(ptreebank)) == 2
        @test length(collect(nptreebank)) == 3

        @testset "Training" begin
            tb = Treebank{CoNLLU}(joinpath(@__DIR__, "data", "hybridtests.conll"))

            for TS in (ArcEager, ArcStandard, ArcHybrid, ArcSwift, ListBasedNonProjective)
                oracle = StaticOracle(TS())
                model(x) = nothing
                update = function (x, pred, gold)
                    # @show x
                end
                trainer = OnlineTrainer(oracle, model, identity, update)

                train!(trainer, tb, epochs=1)
            end

        end
    end

    @testset "Oracles & Projectivity" begin
        tb = Treebank{CoNLLU}(joinpath(datadir, "nonprojective1.conll"))
        np_oracle = StaticOracle(ListBasedNonProjective())
        p_oracle  = StaticOracle(ArcEager())
        @test length(xys(np_oracle, tb)) > 1
        @test length(xys(p_oracle, tb)) == 0
        @test length(xys(p_oracle, first(tb))) == 0

        count = 0
        for (cfg, t) in xys(p_oracle, first(tb))
            count += 1
        end
        @test count == 0
    end
end
