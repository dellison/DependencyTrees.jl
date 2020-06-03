using DependencyTrees: deps, leftdeps, rightdeps, leftmostdep, rightmostdep

@testset "Graphs" begin

    sent = [
        ("Economic", "ATT", 2),
        ("news", "SBJ", 3),
        ("had", "PRED", 0),
        ("little", "ATT", 5),
        ("effect", "OBJ", 3),
        ("on", "ATT", 5),
        ("financial", "ATT", 8),
        ("markets", "PC", 6),
        (".", "PU", 3),
    ]

    graph = deptree(sent) do ((form, deprel, head))
        DependencyTrees.Token(form, head, deprel)
    end
    @test graph == deepcopy(graph)

    @test [t.form for t in graph.tokens] == [first(t) for t in sent]
    for (i, t) in enumerate(sent)
        @test graph.tokens[i].form == first(t)
    end

    @test DependencyTrees.to_conllu(graph) |> strip == """
1	Economic	_	_	_	_	2	ATT	_	_
2	news	_	_	_	_	3	SBJ	_	_
3	had	_	_	_	_	0	PRED	_	_
4	little	_	_	_	_	5	ATT	_	_
5	effect	_	_	_	_	3	OBJ	_	_
6	on	_	_	_	_	5	ATT	_	_
7	financial	_	_	_	_	8	ATT	_	_
8	markets	_	_	_	_	6	PC	_	_
9	.	_	_	_	_	3	PU	_	_
""" |> strip

    @test showstr(graph) ==
        """
        ┌────────────── ROOT
        │           ┌─► Economic
        │        ┌─►└── news
        └─►┌──┌──└───── had
           │  │     ┌─► little
           │  └─►┌──└── effect
           │  ┌──└────► on
           │  │     ┌─► financial
           │  └────►└── markets
           └──────────► .
        """ |> strip

    @test length(graph) == length(sent) == 9
    for (i, (word, tag, id_)) in enumerate(sent)
        sent_deps = filter(x -> x[3] == i, sent)
        deps_ = deps(graph, i)
        @test length(deps_) == length(sent_deps)
        @test Set(graph.tokens[id].form for id in deps_) == Set([d[1] for d in sent_deps])
    end

    @test leftdeps(graph, 0) == []
    @test rightdeps(graph, 0) == [3]
    @test leftdeps(graph, 1) == []
    @test rightdeps(graph, 1) == []
    @test leftdeps(graph, 2) == [1]
    @test rightdeps(graph, 2) == []
    @test leftdeps(graph, 3) == [2]
    @test rightdeps(graph, 3) == [5,9]
    @test leftdeps(graph, 4) == []
    @test rightdeps(graph, 4) == []
    @test leftdeps(graph, 5) == [4]
    @test rightdeps(graph, 5) == [6]
    @test leftdeps(graph, 6) == []
    @test rightdeps(graph, 6) == [8]
    @test leftdeps(graph, 7) == []
    @test rightdeps(graph, 7) == []
    @test leftdeps(graph, 8) == [7]
    @test rightdeps(graph, 8) == []
    @test leftdeps(graph, 9) == []
    @test rightdeps(graph, 9) == []

    @test leftmostdep(graph, 1) == -1
    @test rightmostdep(graph, 1) == -1
    @test leftmostdep(graph, 2) == 1
    @test rightmostdep(graph, 2) == -1
    @test leftmostdep(graph, 3) == 2
    @test rightmostdep(graph, 3) == 9
    @test leftmostdep(graph, 4) == -1
    @test rightmostdep(graph, 4) == -1
    @test leftmostdep(graph, 5) == 4
    @test rightmostdep(graph, 5) == 6
    @test leftmostdep(graph, 6) == -1
    @test rightmostdep(graph, 6) == 8
    @test leftmostdep(graph, 7) == -1
    @test rightmostdep(graph, 7) == -1
    @test leftmostdep(graph, 8) == 7
    @test rightmostdep(graph, 8) == -1
    @test leftmostdep(graph, 9) == -1
    @test rightmostdep(graph, 9) == -1

    sent = [
        ("Pierre", "NNP", 2),
        ("Vinken", "NNP", 8),
        (",", ",", 2),
        ("61", "CD", 5),
        ("years", "NNS", 6),
        ("old", "JJ", 2),
        (",", ",", 2),
        ("will", "MD", 0),
        ("join", "VB", 8),
        ("the", "DT", 11),
        ("board", "NN", 9),
        ("as", "IN", 9),
        ("a", "DT", 15),
        ("nonexecutive", "JJ", 15),
        ("director", "NN", 12),
        ("Nov.", "NNP", 9),
        ("29", "CD", 16),
        (".", ".", 8)
    ]

    graph = deptree(sent) do ((form, label, head))
        DependencyTrees.Token(form, head, label)
    end

    @test length(graph) == length(sent) == 18
    # @test isroot(graph[0])
    for i in 1:length(sent)
        sent_deps = filter(x -> x[3] == i, sent)
        deps_ = deps(graph, i)
        @test length(deps_) == length(sent_deps)
        @test Set(graph[id].form for id in deps_) == Set([d[1] for d in sent_deps])
    end
    # @test isprojective(graph)

    @testset "Projectivity" begin

        # mcdonald & pereira 2005
        # https://www.seas.upenn.edu/~strctlrn/bib/PDF/nonprojectiveHLT-EMNLP2005.pdf
        sent = [
            ("john", 2),      # 1
            ("saw", 0),       # 2
            ("a", 4),         # 3
            ("dog", 2),       # 4
            ("yesterday", 2), # 5
            ("which", 7),     # 6
            ("was", 4),       # 7
            ("a", 9),         # 8
            ("yorkshire", 10),# 9
            ("terrier", 7)    # 10
        ]
        # graph = DependencyTree([Token(fm, hd, id=i) for (i, (fm, hd)) in enumerate(sent)], 2)
        graph = deptree(t -> DependencyTrees.Token(t...), sent)
        # @test !isprojective(graph)

        @test DependencyTrees.to_conllu(graph) |> strip == """
1	john	_	_	_	_	2	_	_	_
2	saw	_	_	_	_	0	_	_	_
3	a	_	_	_	_	4	_	_	_
4	dog	_	_	_	_	2	_	_	_
5	yesterday	_	_	_	_	2	_	_	_
6	which	_	_	_	_	7	_	_	_
7	was	_	_	_	_	4	_	_	_
8	a	_	_	_	_	9	_	_	_
9	yorkshire	_	_	_	_	10	_	_	_
10	terrier	_	_	_	_	7	_	_	_
""" |> strip

        @test showstr(graph) |> strip ==
            """
               ┌─────────── ROOT
               │        ┌─► john
               └─►┌──┌──└── saw
                  │  │  ┌─► a
               ┌──│  └─►└── dog
               │  └───────► yesterday
               │        ┌─► which
            ┌──└───────►└── was
            │           ┌─► a
            │        ┌─►└── yorkshire
            └───────►└───── terrier
            """ |> strip

        # jurafsky & martin, speech & language processing (3ed)
        sent = [
            ("jetblue", "nsubj", 2), # 1
            ("canceled", "root", 0), # 2
            ("our", "det", 4),       # 3
            ("flight", "dobj", 2),   # 4
            ("this", "det", 2),      # 5
            ("morning", "nmod", 7),  # 6
            ("which", "case", 4),    # 7
            ("was", "mod", 9),       # 8
            ("already", "adv", 10),  # 9
            ("late", "mod", 7)       # 10
        ]
        graph = deptree(sent) do ((form, label, head))
            DependencyTrees.Token(form, head, label)
        end
        @test graph[1].label == "nsubj"
    end

    @testset "Errors" begin

        using DependencyTrees: NonProjectiveGraphError

        sent = [
            ("john", 2),      # 1
            ("saw", 0),       # 2
            ("a", 4),         # 3
            ("dog", 2),       # 4
            ("yesterday", 2), # 5
            ("which", 7),     # 6
            ("was", 4),       # 7
            ("a", 9),         # 8
            ("yorkshire", 10),# 9
            ("terrier", 7)    # 10
        ]
        tree = deptree(x -> Token(x...), sent)

        @test !is_projective(tree)

        for system in (ArcEager(), ArcHybrid(), ArcStandard())
            oracle = Oracle(system, static_oracle)
            sequence = oracle(tree)
            @test sequence isa DependencyTrees.TransitionParsing.UnparsableTree
        end
    end

end
