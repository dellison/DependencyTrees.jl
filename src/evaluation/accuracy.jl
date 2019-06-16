"""
    labeled_accuracy(tree, gold)

todo
"""
function labeled_accuracy end

"""
    unlabeled_accuracy(tree, gold)

todo
"""
function unlabeled_accuracy end

const labelled_accuracy = labeled_accuracy
const unlabelled_accuracy = unlabeled_accuracy

accurate(t::Dependency, gold::Dependency) = head(t) == head(gold)

# todo(t::Dependency, gold::Dependency) =
#     head(t) == head(gold) && deprel(a) == deprel(b)

function labeled_accuracy(tree::DependencyTree, gold::DependencyTree)
    results = map(zip(tokens(tree), tokens(gold))) do (t, g)
        head(t) == head(g) && deprel(t) == deprel(g)
    end
    count(results) / length(results)
end

function labeled_accuracy(trees, goldtrees)
    results = Bool[]
    for (tree, gold) in zip(trees, goldtrees)
        # append!(results, compare_trees(labels_accurate, tree, gold))
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
        # append!(results, map((t, g) -> head(t) == head(g),
        #                      zip(tokens(tree), tokens(gold))))
    end
    count(results) / length(results)
end

# unlabeled_accuracy(t::Dependency, gold::Dependency) = head(t) == head(gold)

# function unlabeled_accuracy(tree::DependencyTree, gold::DependencyTree)
#     results = compare_trees(accurate, pred, gold)
#     count(results) / length(results)
# end

# function unlabeled_accuracy(trees, goldtrees)
#     results = Bool[]
#     for (tree, goldtree) in zip(trees, goldtrees)
#         append!(results, compare_trees(accurate, tree, goldtree))
#     end
#     @show results
#     count(results) / length(results)
# end

function compare_trees(compare, t1::DependencyTree, t2::DependencyTree)
    Ta, Tb = tokens(t1), tokens(t2)
    @assert length(Ta) == length(Tb)
    @assert form.(Ta) == form.(Tb) throw(TreeComparisonError(t1, t2))
    # map(compare, Ta, Tb)
    @show compare.(Ta, Tb)
end
