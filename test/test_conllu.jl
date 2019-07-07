@testset "CoNLL-U" begin

    trees = collect(test_treebank("english.conllu"))

    @test length(trees) == 2
    @test length.(trees) == [7, 19]

    for C in [ArcStandard(), ArcEager(), ListBasedNonProjective()], tree in trees
        tokens = form.(tree)
        oracle = StaticOracle(C)
    end

    for C in [ArcEager(), ArcHybrid()]
        oracle = StaticOracle(C, arc = untyped)
        for (cfg, t) in DependencyTrees.xys(oracle, trees)
            @test DT.args(t) == ()
        end
    end

    @test DependencyTrees.noval(CoNLLU).head == -1

    # make sure the errors get thrown correctly
    @test_throws MultiWordTokenError CoNLLU("18-19	cannot	_	_	_	_	_	_	_	SpaceAfter=No")
    @test_throws EmptyTokenError CoNLLU("0.1	nothing	_	_	_	_	_	_	_	_")

    c = CoNLLU("1	Distribution	distribution	NOUN	S	Number=Sing	7	nsubj	_	_")
    @test c.feats == ["Number=Sing"]

    @test_throws Exception CoNLLU("1	2	3")

    sent = """
1	They	they	PRON	PRP	Case=Nom|Number=Plur	2	nsubj	2:nsubj|4:nsubj	_
2	buy	buy	VERB	VBP	Number=Plur|Person=3|Tense=Pres	0	root	0:root	_
3	and	and	CONJ	CC	_	4	cc	4:cc	_
4	sell	sell	VERB	VBP	Number=Plur|Person=3|Tense=Pres	2	conj	0:root|2:conj	_
5	books	book	NOUN	NNS	Number=Plur	2	obj	2:obj|4:obj	_
6	.	.	PUNCT	.	_	2	punct	2:punct	_"""

    graph = DependencyTree{CoNLLU}(sent)
    for d in graph.tokens
        @test untyped(d) == ()
        @test typed(d) == (d.deprel,)
    end
    @test startswith(showstr(graph), "DependencyTree{CoNLLU}\n1\tThey")
    for (i, tok) in enumerate(tokens(graph))
        @test startswith(showstr(tok), string(tok.id))
    end

    c = CoNLLU("1	They	they	PRON	PRP	Case=Nom|Number=Plur	2	nsubj	2:nsubj|4:nsubj	_")
    @test length(c.deps) == 2

    sent = """
1	Sue	Sue	_	_	_	2	_	_	_
2	likes	like	_	_	_	0	_	_	_
3	coffee	coffee	_	_	_	2	_	_	_
4	and	and	_	_	_	2	_	_	_
5	Bill	Bill	_	_	_	2	_	_	_
5.1	likes	like	_	_	_	_	_	_	_
6	tea	tea	_	_	_	2	_	_	_
"""

    graph = DependencyTree{CoNLLU}(sent)
    @test length(graph.emptytokens) == 1
    @test length(graph) == 6

    sent = """
1-2	vámonos	_	_	_	_	_	_	_	_
1	vamos	ir	_	_	_	0	_	_	_
2	nos	nosotros	_	_	_	1	_	_	_
3-4	al	_	_	_	_	_	_	_	_
3	a	a	_	_	_	5	_	_	_
4	el	el	_	_	_	5	_	_	_
5	mar	mar	_	_	_	1	_	_	_
"""

    graph = DependencyTree{CoNLLU}(sent)
    @test length(graph.emptytokens) == 0
    @test length(graph.mwts) == 2
    @test length(graph) == 5
end
