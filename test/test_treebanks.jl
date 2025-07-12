@testset "Treebanks" begin

    datadir = joinpath(@__DIR__, "data")

    @testset "Treebanks" begin
        files = [joinpath(datadir, file) for file in readdir(datadir)
                 if endswith(file, ".conllu")]
        @test length(files) == 3

        @test_throws Exception Treebank("not a corpus")

        tb_emptytokens = Treebank(joinpath(datadir, "emptytokens.conllu"))
        @test length(collect(tb_emptytokens)) == 1

        tb_english = Treebank(joinpath(datadir, "english.conllu"))
        @test length(collect(tb_english)) == 2

        tb_mwt = Treebank(joinpath(datadir, "multiwordtoken.conllu"))
        @test length(collect(tb_mwt)) == 1
        tree = first(tb_mwt)
        @test tree.metadata["sent_id"] == "en_partut-ud-167"
        @test length(tree.tokens) == 24

        np = Treebank(joinpath(datadir, "nonprojective.conll"), conllu)
        @test length(collect(np)) == 3
        @test length(filter(is_projective, collect(np))) == 2
    end

    @testset "Oracles & Projectivity" begin
        tb = Treebank(joinpath(datadir, "nonprojective1.conll"), conllu)
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
