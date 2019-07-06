@testset "Evaluation" begin

    gold = DependencyTree(TypedDependency, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 0),
        (4, ".", ".", 3)])

    good = DependencyTree(TypedDependency, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 0),
        (4, ".", ".", 3)])

    ok = DependencyTree(TypedDependency, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 0),
        (4, ".", "WRONG", 3)])

    bad = DependencyTree(TypedDependency, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 0),
        (4, ".", "WRONG", 2)])

    @test unlabeled_accuracy(gold, good) == 1
    @test unlabeled_accuracy(gold, ok)   == 1
    @test unlabeled_accuracy(gold, bad)  == 0.75

    @test labeled_accuracy(gold, good) == 1
    @test labeled_accuracy(gold, ok)   == 0.75
    @test labeled_accuracy(gold, bad)  == 0.75

    @test unlabeled_accuracy([gold], [good]) == 1
    @test unlabeled_accuracy([gold], [ok])   == 1
    @test unlabeled_accuracy([gold], [bad])  == 0.75

    @test labeled_accuracy([gold], [good]) == 1
    @test labeled_accuracy([gold], [ok])   == 0.75
    @test labeled_accuracy([gold], [bad])  == 0.75
end
