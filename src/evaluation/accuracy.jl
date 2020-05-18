"""
    labeled_accuracy(prediction, gold)

Accuracy score for dependency arcs, including the labels.
"""
function labeled_accuracy end

"""
    unlabeled_accuracy(prediction, gold)

Accuracy score for dependency arcs, not including the labels.
"""
function unlabeled_accuracy end

const labelled_accuracy = labeled_accuracy
const unlabelled_accuracy = unlabeled_accuracy

function labeled_accuracy(tree::DependencyTree, gold::DependencyTree)
    results = map(zip(tree, gold)) do (t, g)
        t.head == g.head && t.label == g.label
    end
    count(results) / length(results)
end

function labeled_accuracy(trees, goldtrees)
    # results = Bool[]
    correct, total = 0, 0
    for (tree, gold) in zip(trees, goldtrees)
        for (t, g) in zip(tree, gold)
            # append!(results, head(t) == head(g) && deprel(t) == deprel(g))
            # @show t
            if t.head == g.head && t.label == g.label
                correct += 1
            end
            total += 1
        end
    end
    return correct / total
end

function unlabeled_accuracy(tree::DependencyTree, gold::DependencyTree)
    results = map(zip(tree, gold)) do (t, g)
        t.head == g.head
    end
    count(results) / length(results)
end

function unlabeled_accuracy(trees, goldtrees)
    correct, total = 0, 0
    for (tree, gold) in zip(trees, goldtrees)
        for (t, g) in zip(tree, gold)
            if t.head == g.head
                correct += 1
            end
            total += 1
        end
    end
    correct / total
end
