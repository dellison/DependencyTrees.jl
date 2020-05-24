module DependencyTrees

export
    DependencyTree,
    deptree, deptoken,
    is_projective,
    Treebank,
    from_conllu,

    typed, untyped,

    labeled_accuracy, unlabeled_accuracy


using Random

import Base.==
import Base.getindex
import Base.reduce
import Base: iterate, IteratorSize, length

include("errors.jl")
include("tokens.jl")
include("trees.jl")
include("conllu.jl")

include("treebanks.jl")

include("transition_parsing/TransitionParsing.jl")
using .TransitionParsing

include("evaluation/accuracy.jl")

end # module
