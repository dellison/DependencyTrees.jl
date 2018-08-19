using DependencyTrees, Test

# synthesis lectures book
@testset "kubler et al 09" begin
    sent = [
        ("Economic", "ATT", 2),
        ("news", "SBJ", 3),
        ("had", "PRED", 0),
        ("little", "ATT", 5),
        ("effect", "OBJ", 3),
        ("on", "ATT", 5),
        ("ﬁnancial", "ATT", 8),
        ("markets", "PC", 6),
        (".", "PU", 3),
    ]
    graph_noroot = DependencyGraph(sent, add_root=false)
    @test length(graph_noroot) == 9
    graph = DependencyGraph(sent)
    @test length(graph) == 10
end

@testset "wsj01" begin
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
    graph_noroot = DependencyGraph(sent, add_root=false)
    @test length(graph_noroot) == 18
end
