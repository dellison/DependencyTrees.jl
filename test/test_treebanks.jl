@testset "Treebanks" begin

    datadir = joinpath(@__DIR__, "data")

    # @testset "Treebank Readers" begin
    #     @testset "Typed" begin
    #         # T = TypedDependency
    #         # tb1 = TreebankReader{T}(joinpath(datadir, "wsj_0001.dp"), add_id=true)
    #         # tb2 = TreebankReader{T}(joinpath(datadir, "wsj_0001.ids.dp"), add_id=false)
    #         # @test deptype(tb1) == deptype(tb2) == T
    #         # @test collect(tb1) == collect(tb2)
    #         # tb1 = Treeba
    #     end

    #     @testset "Untyped" begin
    #         T = UntypedDependency
    #         tb1 = TreebankReader{T}(joinpath(datadir, "wsj_0001.untyped.dp"), add_id=true)
    #         tb2 = TreebankReader{T}(joinpath(datadir, "wsj_0001.untyped.ids.dp"), add_id=false)
    #         @test deptype(tb1) == deptype(tb2) == T
    #         @test collect(tb1) == collect(tb2)
    #     end

    #     @testset "CoNLLU Multiword Tokens" begin
    #         tree = collect(TreebankReader{CoNLLU}(joinpath(datadir, "multiwordtoken.conllu")))[1]
    #         @test length(tree) == 24
    #         @test length(tree.mwts) == 1
    #         @test length(tree.emptytokens) == 0
    #     end


    #     @testset "CoNLLU Empty Tokens" begin
    #         tree = collect(TreebankReader{CoNLLU}(joinpath(datadir, "emptytokens.conllu")))[1]
    #         @test length(tree) == 6
    #         @test length(tree.mwts) == 0
    #         @test length(tree.emptytokens) == 1
    #     end
    # end

    @testset "Treebanks" begin
        files = [joinpath(datadir, file) for file in readdir(datadir)
                 if endswith(file, ".conllu")]
        @test length(files) == 3

        @test_throws Exception Treebank("not a corpus")

        treebank = Treebank(files)
        @test showstr(treebank) == "Treebank (3 files)"
        trees = collect(treebank)
        @test length(trees) == 4
        # @test deptype(treebank) == CoNLLU

        # treebank2 = Treebank(datadir, pattern=r".conllu$")
        # trees2 = collect(treebank2)
        # @test length(trees2) == 4
        # @test trees2 == trees

        # for TS in (ArcEager, ArcHybrid, ArcStandard, ArcSwift)
        #     oracle = StaticOracle(TS())
        #     @test collect(xys(oracle, trees)) == collect(xys(oracle, trees2))
        # end

        # np = joinpath(datadir, "nonprojective.conll")
        # ptreebank = Treebank(np, allow_nonprojective=false)
        # nptreebank = Treebank(np, allow_nonprojective=true)
        # @test length(collect(ptreebank)) == 2
        # @test length(collect(nptreebank)) == 3
        np = Treebank(joinpath(datadir, "nonprojective.conll"))
        @test length(collect(np)) == 3
        @test length(filter(is_projective, collect(np))) == 2
    end

    @testset "Oracles & Projectivity" begin
        tb = Treebank(joinpath(datadir, "nonprojective1.conll"))
        # np_oracle = StaticOracle(ListBasedNonProjective())
        # p_oracle  = StaticOracle(ArcEager())
        np_oracle = Oracle(ListBasedNonProjective(), static_oracle, untyped)
        p_oracle = Oracle(ArcEager(), static_oracle, untyped)
        np_data = collect(Iterators.flatten(np_oracle.(tb)))
        p_data = collect(Iterators.flatten(p_oracle.(tb)))
        @test length(np_data) > 1
        @test length(p_data) == 0
        @test length(p_oracle(first(tb))) == 0

        count = 0
        for (cfg, t) in p_oracle(first(tb))
            count += 1
        end
        @test count == 0
    end
end
