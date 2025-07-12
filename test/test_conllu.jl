@testset "CoNLL-U" begin

    # sentences:
    # From the AP comes this story:
    # President Bush on Tuesday confirmed ...
    trees = collect(test_treebank("english.conllu"))

    @test length(trees) == 2
    @test length.(trees) == [7, 19]

    transition_systems = [ArcStandard(), ArcEager(), ListBasedNonProjective()]
    for C in transition_systems, tree in trees
        tokens = [t.form for t in tree]
        oracle = Oracle(C, static_oracle)
    end

    for C in [ArcEager(), ArcHybrid()]
        oracle = Oracle(C, static_oracle, untyped)
        for (cfg, t) in Iterators.flatten(oracle.(trees))
            # @test DT.args(t) == ()
        end
    end

    # @test DependencyTrees.noval(CoNLLU).head == -1

    using DependencyTrees: conllu
    # make sure the errors get thrown correctly
    # @test_throws MultiWordTokenError conllu("18-19	cannot	_	_	_	_	_	_	_	SpaceAfter=No")
    # @test_throws EmptyTokenError conllu("0.1	nothing	_	_	_	_	_	_	_	_")

    c = conllu("1	Distribution	distribution	NOUN	S	Number=Sing	7	nsubj	_	_")
    token = c.tokens[1]
    @test token.feats == ["Number=Sing"]
    @test token.lemma == "distribution"

    sent = """
1	They	they	PRON	PRP	Case=Nom|Number=Plur	2	nsubj	2:nsubj|4:nsubj	_
2	buy	buy	VERB	VBP	Number=Plur|Person=3|Tense=Pres	0	root	0:root	_
3	and	and	CONJ	CC	_	4	cc	4:cc	_
4	sell	sell	VERB	VBP	Number=Plur|Person=3|Tense=Pres	2	conj	0:root|2:conj	_
5	books	book	NOUN	NNS	Number=Plur	2	obj	2:obj|4:obj	_
6	.	.	PUNCT	.	_	2	punct	2:punct	_"""

    graph = conllu(sent)
    for d in graph.tokens
        @test untyped(d) == ()
        @test typed(d) == (d.deprel,)
    end

    c = conllu("1	They	they	PRON	PRP	Case=Nom|Number=Plur	2	nsubj	2:nsubj|4:nsubj	_")
    @test length(c.tokens[1].deps) == 2

    sent = """
1	Sue	Sue	_	_	_	2	_	_	_
2	likes	like	_	_	_	0	_	_	_
3	coffee	coffee	_	_	_	2	_	_	_
4	and	and	_	_	_	2	_	_	_
5	Bill	Bill	_	_	_	2	_	_	_
5.1	likes	like	_	_	_	_	_	_	_
6	tea	tea	_	_	_	2	_	_	_
"""

    graph = conllu(sent)
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
    graph = conllu(sent)
    @test length(graph) == 5
    # @test_throws DependencyTrees.MultiWordTokenError conllu("1-2	vámonos	_	_	_	_	_	_	_	_")
    # todo test this


    @testset "Metadata" begin
        sent = """
# newdoc id = weblog-juancole.com_juancole_20051126063000_ENG_20051126_063000
# sent_id = weblog-juancole.com_juancole_20051126063000_ENG_20051126_063000-0001
# newpar id = weblog-juancole.com_juancole_20051126063000_ENG_20051126_063000-p0001
# text = Al-Zaman : American forces killed Shaikh Abdullah al-Ani, the preacher at the mosque in the town of Qaim, near the Syrian border.
1	Al	Al	PROPN	_	Number=Sing	0	root	_	_
2	-	-	PUNCT	_	_	_	_	_	_
3	Zaman	Zaman	PROPN	_	Number=Sing	1	flat	_	_
4	:	:	PUNCT	_	_	_	_	_	_
5	American	American	ADJ	_	Degree=Pos	6	amod	_	_
6	forces	force	NOUN	_	Number=Plur	7	nsubj	_	_
7	killed	kill	VERB	_	Mood=Ind|Polarity=Pos|Tense=Past|VerbForm=Fin|Voice=Act	1	parataxis	_	_
8	Shaikh	Shaikh	PROPN	_	Number=Sing	7	obj	_	_
9	Abdullah	Abdullah	PROPN	_	Number=Sing	8	flat	_	_
10	al	al	PROPN	_	Number=Sing	8	flat	_	_
11	-	-	PUNCT	_	_	_	_	_	_
12	Ani	Ani	PROPN	_	Number=Sing	8	flat	_	_
13	,	,	PUNCT	_	_	_	_	_	_
14	the	the	DET	_	_	_	_	_	_
15	preacher	preacher	NOUN	_	Definite=Def|Number=Sing	8	appos	_	_
16	at	at	ADP	_	_	_	_	_	_
17	the	the	DET	_	_	_	_	_	_
18	mosque	mosque	NOUN	_	Case=Loc|Definite=Def|Number=Sing	15	nmod	_	_
19	in	in	ADP	_	_	_	_	_	_
20	the	the	DET	_	_	_	_	_	_
21	town	town	NOUN	_	Case=Ine|Definite=Def|Number=Sing	18	nmod	_	_
22	of	of	ADP	_	_	_	_	_	_
23	Qaim	Qaim	PROPN	_	Case=Gen|Number=Sing	21	nmod	_	_
24	,	,	PUNCT	_	_	_	_	_	_
25	near	near	ADP	_	_	_	_	_	_
26	the	the	DET	_	_	_	_	_	_
27	Syrian	Syrian	ADJ	_	Degree=Pos	28	amod	_	_
28	border	border	NOUN	_	Case=Prx|Definite=Def|Number=Sing	21	nmod	_	_
29	.	.	PUNCT	_	_	_	_	_	_
"""
        tree = conllu(sent)
        @test length(tree) == 29
        @test tree.metadata["sent_id"] == "weblog-juancole.com_juancole_20051126063000_ENG_20051126_063000-0001"
    end
end
