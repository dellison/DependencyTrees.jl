using DependencyTrees: CoNLLU

@testset "CoNLL-U" begin

    corpus_file = joinpath(@__DIR__, "data", "english.conllu")

    trees = DependencyTrees.TreebankReader{CoNLLU}(corpus_file) |> collect
    @test length(trees) == 2
    @test length.(trees) == [7, 19]

    for C in [ArcStandard, ArcEager, ListBasedNonProjective], tree in trees
        tokens = form.(tree)
        oracle = DependencyTrees.static_oracle(C, tree)

        parsed =  DependencyTrees.parse(C{CoNLLU}, tokens, oracle)
        @test length(tree) == length(parsed)
        for (i, gold_node) in enumerate(tree)
            @test deprel(parsed, i) == deprel(gold_node)
        end
    end

    # for now just make sure the errors get thrown correctly
    using DependencyTrees: MultiWordTokenError, EmptyNodeError
    @test_throws MultiWordTokenError CoNLLU("18-19	cannot	_	_	_	_	_	_	_	SpaceAfter=No")
    @test_throws EmptyNodeError CoNLLU("0.1	nothing	_	_	_	_	_	_	_	_")
end
