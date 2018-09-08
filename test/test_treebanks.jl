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

end
