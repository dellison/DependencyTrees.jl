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
    correct, total = 0, 0
    for (t, g) in zip(tree, gold)
        t.head == g.head && t.label == g.label && (correct += 1)
        total += 1
    end
    return correct / total
end

function labeled_accuracy(trees, goldtrees)
    correct, total = 0, 0
    for (tree, gold) in zip(trees, goldtrees), (t, g) in zip(tree, gold)
        t.head == g.head && t.label == g.label && (correct += 1)
        total += 1
    end
    return correct / total
end

function unlabeled_accuracy(tree::DependencyTree, gold::DependencyTree)
    correct, total = 0, 0
    for (t, g) in zip(tree, gold)
        t.head == g.head && (correct += 1)
        total += 1
    end
    return correct / total
end

function unlabeled_accuracy(trees, goldtrees)
    correct, total = 0, 0
    for (tree, gold) in zip(trees, goldtrees), (t, g) in zip(tree, gold)
        t.head == g.head && (correct += 1)
        total += 1
    end
    return correct / total
end
