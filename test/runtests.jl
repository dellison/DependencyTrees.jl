using DependencyTrees, Test
using DependencyTrees: deprel, form, id, head, root, isroot

@testset "Tokens" begin

    @testset "Untyped Dependencies" begin
        r = root(UntypedDependency)
        @test isroot(r)
        sent = [
            ("The", 2),
            ("cat", 3),
            ("slept", 0),
            (".", 3)
        ]
        for (i, token) in enumerate(sent)
            dep = UntypedDependency(i, token...)
            @test deprel(dep) == nothing
            @test form(dep) == token[1]
            @test id(dep) == i
            @test !isroot(dep)
            @test head(dep) == token[2]
        end

        g1 = DependencyGraph([UntypedDependency(i, t...) for (i, t) in enumerate(sent)])
        g2 = DependencyGraph(UntypedDependency, sent)
        @test g1 == g2
    end

    @testset "Labeled Dependencies" begin
        r = root(LabeledDependency)
        @test isroot(r)
        sent = [
            ("The", "DT", 2),
            ("cat", "NN", 3),
            ("slept", "VBD", 0),
            (".", ".", 3)
        ]
        for (i, token) in enumerate(sent)
            dep = LabeledDependency(i, token...)
            @test form(dep) == token[1]
            @test deprel(dep) == token[2]
            @test head(dep) == token[3]
            @test id(dep) == i
            @test !isroot(dep)
        end
    end
end

@testset "Graphs" begin

    using DependencyTrees: dependents

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

    graph = DependencyGraph(LabeledDependency, sent)

    @test length(graph) == length(sent) == 9
    @test isroot(graph[0])
    for (i, (word, tag, id_)) in enumerate(sent)
        @test i == id(graph[i])
        sent_deps = filter(x -> x[3] == i, sent)
        deps_ = dependents(graph, i)
        @test length(deps_) == length(sent_deps)
        @test Set(form(graph, id) for id in deps_) == Set([d[1] for d in sent_deps])
    end

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

    graph = DependencyGraph(LabeledDependency, sent)

    @test length(graph) == length(sent) == 18
    @test isroot(graph[0])
    for (i, token) in enumerate(sent)
        @test i == id(graph[i])
        sent_deps = filter(x -> x[3] == i, sent)
        deps_ = dependents(graph, i)
        @test length(deps_) == length(sent_deps)
        @test Set(form(graph, id) for id in deps_) == Set([d[1] for d in sent_deps])
    end
end
