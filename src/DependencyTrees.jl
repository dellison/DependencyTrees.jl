module DependencyTrees

export
    DependencyTree, isprojective,
    Treebank,
    TypedDependency, UntypedDependency, CoNLLU,

    ArcEager, ArcEagerReduce, ArcEagerShift,
    ArcStandard, ArcHybrid, ArcSwift, ListBasedNonProjective,

    StaticOracle, DynamicOracle, static_oracle,

    typed, untyped,
    initconfig, isfinal, possible_transitions,

    labeled_accuracy, unlabeled_accuracy


using Random
using LightGraphs

import Base.==
import Base.getindex
import Base.reduce

include("errors.jl")
include("dependencies.jl")
include("conllu.jl")
include("trees.jl")

include("treebanks/treebanks.jl")

include("graph_parsing/parse.jl")
include("transition_parsing/parse.jl")

include("evaluation/accuracy.jl")

end # module
