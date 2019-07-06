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
    results = map(zip(tokens(tree), tokens(gold))) do (t, g)
        head(t) == head(g) && deprel(t) == deprel(g)
    end
    count(results) / length(results)
end

function labeled_accuracy(trees, goldtrees)
    results = Bool[]
    for (tree, gold) in zip(trees, goldtrees)
        for (t, g) in zip(tokens(tree), tokens(gold))
            append!(results, head(t) == head(g) && deprel(t) == deprel(g))
        end
    end
    count(results) / length(results)
end

function unlabeled_accuracy(tree::DependencyTree, gold::DependencyTree)
    results = map(zip(tokens(tree), tokens(gold))) do (t, g)
        head(t) == head(g)
    end
    count(results) / length(results)
end

function unlabeled_accuracy(trees, goldtrees)
    results = Bool[]
    for (tree, gold) in zip(trees, goldtrees)
        for (t, g) in zip(tokens(tree), tokens(gold))
            push!(results, head(t) == head(g))
        end
    end
    count(results) / length(results)
end
