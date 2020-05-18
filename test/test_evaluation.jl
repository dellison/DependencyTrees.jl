@testset "Evaluation" begin

    f = x -> DependencyTrees.from_indices(x, form=2, label=3, head=4, id=1)

    gold = deptree(f, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 0),
        (4, ".", ".", 3)])

    good = deptree(f, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 0),
        (4, ".", ".", 3)])

    ok = deptree(f, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 0),
        (4, ".", "WRONG", 3)])

    bad = deptree(f, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 0),
        (4, ".", "WRONG", 2)])

    worse = deptree(f, [
        (1, "The", "DT", 2),
        (2, "cat", "NSUBJ", 3),
        (3, "sleeps", "PRED", 2),
        (4, ".", "WRONG", 0)])
                    

    @test unlabeled_accuracy(gold, good) == 1
    @test unlabeled_accuracy(gold, ok)   == 1
    @test unlabeled_accuracy(gold, bad)  == 0.75
    @test unlabeled_accuracy(gold, worse)  == 0.5

    @test labeled_accuracy(gold, good) == 1
    @test labeled_accuracy(gold, ok)   == 0.75
    @test labeled_accuracy(gold, bad)  == 0.75
    @test labeled_accuracy(gold, worse)  == 0.5

    @test unlabeled_accuracy([gold], [good]) == 1
    @test unlabeled_accuracy([gold], [ok])   == 1
    @test unlabeled_accuracy([gold], [bad])  == 0.75
    @test unlabeled_accuracy([gold], [worse])  == 0.5

    @test labeled_accuracy([gold], [good]) == 1
    @test labeled_accuracy([gold], [ok])   == 0.75
    @test labeled_accuracy([gold], [bad])  == 0.75
    @test labeled_accuracy([gold], [worse])  == 0.5
end
