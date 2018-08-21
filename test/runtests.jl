using DependencyTrees, Test

@testset "Tokens" begin

    using DependencyTrees: deprel, form, id, head, root, isroot

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
    deps = [LabeledDependency(id, tok...) for (id, tok) in enumerate(sent)]

    graph = DependencyGraph(deps, add_root=true)
    graph_noroot = DependencyGraph(deps, add_root=false)

    @test length(graph) == 10
    @test length(graph_noroot) == 9


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
    deps = [LabeledDependency(id, tok...) for (id, tok) in enumerate(sent)]

    graph = DependencyGraph(deps, add_root=true)
    @test DependencyTrees.isroot(graph[1])

    graph_noroot = DependencyGraph(deps, add_root=false)
    @test !DependencyTrees.isroot(graph_noroot[1])

    @test length(graph) == 19
    @test length(graph_noroot) == 18
end
