module DependencyTrees

export
    DependencyTree,
    is_projective,
    Treebank,
    conllu, conllx,

    typed, untyped,

    labeled_accuracy, unlabeled_accuracy

import Base.==
import Base.getindex
import Base.reduce
import Base: iterate, IteratorSize, length

include("errors.jl")
include("tokens.jl")
include("trees.jl")
include("conllx.jl")
include("conllu.jl")

include("treebanks.jl")

include("transition_parsing/TransitionParsing.jl")
using .TransitionParsing

include("graph_parsing/GraphParsing.jl")
using .GraphParsing

include("evaluation.jl")

end # module
