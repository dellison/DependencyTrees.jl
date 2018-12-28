using DependencyTrees: dependents, leftdeps, rightdeps, leftmostdep, rightmostdep

@testset "Graphs" begin

    line = "1	From	_	ADP	IN	_	3	case	_	_"
    d = CoNLLU(line)
    @test strip(DependencyTrees.toconllu(d)) == line

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

    graph = DependencyGraph(TypedDependency, sent, add_id=true)

    @test eltype(graph) == DependencyTrees.deptype(graph) == TypedDependency
    @test isroot(root(graph))

    @test length(graph) == length(sent) == 9
    @test isroot(graph[0])
    for (i, (word, tag, id_)) in enumerate(sent)
        @test i == id(graph[i])
        sent_deps = filter(x -> x[3] == i, sent)
        deps_ = dependents(graph, i)
        @test length(deps_) == length(sent_deps)
        @test Set(form(graph, id) for id in deps_) == Set([d[1] for d in sent_deps])
    end
    @test isprojective(graph)

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

    @test leftmostdep(graph, 0) == -1
    @test leftmostdep(graph, graph[0]).id == -1
    @test leftmostdep(graph.tokens, graph[0]).id == -1
    @test rightmostdep(graph, 0) == 3
    @test rightmostdep(graph, graph[0]).id == 3
    @test rightmostdep(graph.tokens, graph[0]).id == 3

    @test leftmostdep(graph, 1) == -1
    @test leftmostdep(graph, graph[1]).id == -1
    @test leftmostdep(graph.tokens, graph[1]).id == -1
    @test rightmostdep(graph, 1) == -1
    @test rightmostdep(graph, graph[1]).id == -1
    @test rightmostdep(graph.tokens, graph[1]).id == -1

    @test leftmostdep(graph, 2) == 1
    @test leftmostdep(graph, graph[2]).id == 1
    @test leftmostdep(graph.tokens, graph[2]).id == 1
    @test rightmostdep(graph, 2) == -1
    @test rightmostdep(graph, graph[2]).id == -1
    @test rightmostdep(graph.tokens, graph[2]).id == -1

    @test leftmostdep(graph, 3) == 2
    @test leftmostdep(graph, graph[3]).id == 2
    @test leftmostdep(graph.tokens, graph[3]).id == 2
    @test rightmostdep(graph, 3) == 9
    @test rightmostdep(graph, graph[3]).id == 9
    @test rightmostdep(graph.tokens, graph[3]).id == 9

    @test leftmostdep(graph, 4) == -1
    @test leftmostdep(graph, graph[4]).id == -1
    @test leftmostdep(graph.tokens, graph[4]).id == -1
    @test rightmostdep(graph, 4) == -1
    @test rightmostdep(graph, graph[4]).id == -1
    @test rightmostdep(graph.tokens, graph[4]).id == -1

    @test leftmostdep(graph, 5) == 4
    @test leftmostdep(graph, graph[5]).id == 4
    @test leftmostdep(graph.tokens, graph[5]).id == 4
    @test rightmostdep(graph, 5) == 6
    @test rightmostdep(graph, graph[5]).id == 6
    @test rightmostdep(graph.tokens, graph[5]).id == 6

    @test leftmostdep(graph, 6) == -1
    @test leftmostdep(graph, graph[6]).id == -1
    @test leftmostdep(graph.tokens, graph[6]).id == -1
    @test rightmostdep(graph, 6) == 8
    @test rightmostdep(graph, graph[6]).id == 8
    @test rightmostdep(graph.tokens, graph[6]).id == 8

    @test leftmostdep(graph, 7) == -1
    @test leftmostdep(graph, graph[7]).id == -1
    @test leftmostdep(graph.tokens, graph[7]).id == -1
    @test rightmostdep(graph, 7) == -1
    @test rightmostdep(graph, graph[7]).id == -1
    @test rightmostdep(graph.tokens, graph[7]).id == -1

    @test leftmostdep(graph, 8) == 7
    @test leftmostdep(graph, graph[8]).id == 7
    @test leftmostdep(graph.tokens, graph[8]).id == 7
    @test rightmostdep(graph, 8) == -1
    @test rightmostdep(graph, graph[8]).id == -1
    @test rightmostdep(graph.tokens, graph[8]).id == -1

    @test leftmostdep(graph, 9) == -1
    @test leftmostdep(graph, graph[9]).id == -1
    @test leftmostdep(graph.tokens, graph[9]).id == -1
    @test rightmostdep(graph, 9) == -1
    @test rightmostdep(graph, graph[9]).id == -1
    @test rightmostdep(graph.tokens, graph[9]).id == -1

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

    graph = DependencyGraph(TypedDependency, sent, add_id=true)

    @test length(graph) == length(sent) == 18
    @test isroot(graph[0])
    for (i, token) in enumerate(sent)
        @test i == id(graph[i])
        sent_deps = filter(x -> x[3] == i, sent)
        deps_ = dependents(graph, i)
        @test length(deps_) == length(sent_deps)
        @test Set(form(graph, id) for id in deps_) == Set([d[1] for d in sent_deps])
    end
    @test isprojective(graph)

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
        graph = DependencyGraph(UntypedDependency, sent, add_id=true)
        @test !isprojective(graph)

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

        graph = DependencyGraph(TypedDependency, sent, add_id=true)
        @test !isprojective(graph)
    end

    @testset "Errors" begin

        using DependencyTrees: GraphConnectivityError, RootlessGraphError, MultipleRootsError, NonProjectiveGraphError

        noroot = [("no", 2), ("root", 1)]
        @test_throws RootlessGraphError DependencyGraph(UntypedDependency, noroot, add_id=true)

        tworoots = [("two", 0), ("roots", 0)]
        @test_throws MultipleRootsError DependencyGraph(UntypedDependency, tworoots, add_id=true)

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
        @test_throws NonProjectiveGraphError DependencyGraph(UntypedDependency, sent, add_id=true, check_projective=true)
    end

end
