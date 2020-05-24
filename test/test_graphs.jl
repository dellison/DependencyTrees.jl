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

    @test [t.form for t in graph.tokens] == [first(t) for t in sent]
    for (i, t) in enumerate(sent)
        @test graph.tokens[i].form == first(t)
        # @test [t.form for t in graph.tokens[1, i])] == ["Economic", first(t)]
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

    # @test showstr(graph) |> strip == """
    @test showstr(graph) == "DependencyTree: Economic news had little effect on financial markets ."


    # @test eltype(graph) == DependencyTrees.deptype(graph) == TypedDependency
    # @test isroot(root(graph))

    @test length(graph) == length(sent) == 9
    # @test isroot(graph[0])
    for (i, (word, tag, id_)) in enumerate(sent)
        # @test i == graph.tokens[i].id
        sent_deps = filter(x -> x[3] == i, sent)
        deps_ = deps(graph, i)
        @test length(deps_) == length(sent_deps)
        @test Set(graph.tokens[id].form for id in deps_) == Set([d[1] for d in sent_deps])
    end
    # @test isprojective(graph)

    # @test leftdeps(graph, graph[0]) == []
    # @test rightdeps(graph, graph[0]) == [graph[3]]

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

    # @test leftmostdep(graph, 0) == -1
    # @test leftmostdep(graph, graph[0]).id == -1
    # @test leftmostdep(graph.tokens, graph[0]).id == -1
    # @test rightmostdep(graph, 0) == 3
    # @test rightmostdep(graph, graph[0]).id == 3
    # @test rightmostdep(graph.tokens, graph[0]).id == 3

    @test leftmostdep(graph, 1) == -1
    # @test leftmostdep(graph, graph[1]).id == -1
    @test rightmostdep(graph, 1) == -1
    # @test rightmostdep(graph, graph[1]).id == -1

    @test leftmostdep(graph, 2) == 1
    # @test leftmostdep(graph, graph[2]).id == 1
    @test rightmostdep(graph, 2) == -1
    # @test rightmostdep(graph, graph[2]).id == -1

    @test leftmostdep(graph, 3) == 2
    # @test leftmostdep(graph, graph[3]).id == 2
    # @test leftmostdep(graph.tokens, graph[3]).id == 2
    @test rightmostdep(graph, 3) == 9
    # @test rightmostdep(graph, graph[3]).id == 9
    # @test rightmostdep(graph.tokens, graph[3]).id == 9

    @test leftmostdep(graph, 4) == -1
    # @test leftmostdep(graph, graph[4]).id == -1
    # @test leftmostdep(graph.tokens, graph[4]).id == -1
    @test rightmostdep(graph, 4) == -1
    # @test rightmostdep(graph, graph[4]).id == -1
    # @test rightmostdep(graph.tokens, graph[4]).id == -1

    @test leftmostdep(graph, 5) == 4
    # @test leftmostdep(graph, graph[5]).id == 4
    # @test leftmostdep(graph.tokens, graph[5]).id == 4
    @test rightmostdep(graph, 5) == 6
    # @test rightmostdep(graph, graph[5]).id == 6
    # @test rightmostdep(graph.tokens, graph[5]).id == 6

    @test leftmostdep(graph, 6) == -1
    # @test leftmostdep(graph, graph[6]).id == -1
    # @test leftmostdep(graph.tokens, graph[6]).id == -1
    @test rightmostdep(graph, 6) == 8
    # @test rightmostdep(graph, graph[6]).id == 8
    # @test rightmostdep(graph.tokens, graph[6]).id == 8

    @test leftmostdep(graph, 7) == -1
    # @test leftmostdep(graph, graph[7]).id == -1
    # @test leftmostdep(graph.tokens, graph[7]).id == -1
    @test rightmostdep(graph, 7) == -1
    # @test rightmostdep(graph, graph[7]).id == -1
    # @test rightmostdep(graph.tokens, graph[7]).id == -1

    @test leftmostdep(graph, 8) == 7
    # @test leftmostdep(graph, graph[8]).id == 7
    # @test leftmostdep(graph.tokens, graph[8]).id == 7
    @test rightmostdep(graph, 8) == -1
    # @test rightmostdep(graph, graph[8]).id == -1
    # @test rightmostdep(graph.tokens, graph[8]).id == -1

    @test leftmostdep(graph, 9) == -1
    # @test leftmostdep(graph, graph[9]).id == -1
    # @test leftmostdep(graph.tokens, graph[9]).id == -1
    @test rightmostdep(graph, 9) == -1
    # @test rightmostdep(graph, graph[9]).id == -1
    # @test rightmostdep(graph.tokens, graph[9]).id == -1

    # sent1 = [
    #     (1, "Economic", "ATT", 2),
    #     (2, "news", "SBJ", 3),
    #     (3, "had", "PRED", 0),
    #     (4, "little", "ATT", 5),
    #     (5, "effect", "OBJ", 3),
    #     (6, "on", "ATT", 5),
    #     (7, "financial", "ATT", 8),
    #     (8, "markets", "PC", 6),
    #     (9, ".", "PU", 3),
    # ]
    # @test graph == DependencyTree(TypedDependency, sent1, add_id=false)


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

    # graph = DependencyTree(TypedDependency, sent, add_id=true)
    # graph = DependencyTree([Token(f, h, id=i, deprel=d) for (i, (f, d, h)) in enumerate(sent)], 3)
    # graph = DependencyTrees.xs_to_deptree(sent, form=1, deprel=2, head=3)
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

        @test showstr(graph) |> strip == "DependencyTree: john saw a dog yesterday which was a yorkshire terrier"

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

        # graph = DependencyTree(TypedDependency, sent, add_id=true)
        # graph = DependencyTrees.xs_to_deptree(sent, form=1, deprel=2, head=3)
        graph = deptree(sent) do ((form, label, head))
            DependencyTrees.Token(form, head, label)
        end
        # @test !isprojective(graph)
        @test graph[1].label == "nsubj"
    end

    @testset "Errors" begin

        using DependencyTrees: RootlessGraphError, MultipleRootsError, NonProjectiveGraphError

        noroot = [("no", 2), ("root", 1)]
        # @show DependencyTrees.to_deptree(noroot; form=1, head=2)
        # @test_throws RootlessGraphError DependencyTrees.to_deptree(noroot; form=1, head=2)

        tworoots = [("two", 0), ("roots", 0)]
        # @test_throws MultipleRootsError DependencyTree(UntypedDependency, tworoots, add_id=true)
        # @test_throws GraphConnectivityError begin
        #     # DependencyTree(UntypedDependency, [(1, "the", 0), (2, "cat", -1)])
        # end

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
        # @test_throws NonProjectiveGraphError DependencyTree(UntypedDependency, sent, add_id=true, check_projective=true)
    end

end
