@testset "Treebanks" begin

    datadir = joinpath(@__DIR__, "data")

    @testset "Treebanks" begin
        files = [joinpath(datadir, file) for file in readdir(datadir)
                 if endswith(file, ".conllu")]
        @test length(files) == 3

        @test_throws Exception Treebank("not a corpus")

        treebank = Treebank(files)
        @test showstr(treebank) == "Treebank (3 files)"
        trees = collect(treebank)
        @test length(trees) == 4

        np = Treebank(joinpath(datadir, "nonprojective.conll"))
        @test length(collect(np)) == 3
        @test length(filter(is_projective, collect(np))) == 2
    end

    @testset "Oracles & Projectivity" begin
        tb = Treebank(joinpath(datadir, "nonprojective1.conll"))
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
