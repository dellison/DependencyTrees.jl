module DependencyTrees

export
    DependencyTree, is_projective,
    Treebank,
    # TypedDependency, UntypedDependency, CoNLLU,
    deptree,

    typed, untyped,
    
    ArcEager, ArcEagerReduce, ArcEagerShift,
    ArcStandard, ArcHybrid, ArcSwift, ListBasedNonProjective,

    StaticOracle, static_oracle, static_oracle_prefer_shift,

    DynamicOracle, dynamic_oracle,

    AlwaysExplore, NeverExplore, ExplorationPolicy,

    initconfig, isfinal, possible_transitions,
    stacktoken, buffertoken,

    labeled_accuracy, unlabeled_accuracy


using Random
# using LightGraphs

import Base.==
import Base.getindex
import Base.reduce
import Base: iterate, IteratorSize, length

include("errors.jl")
include("tokens.jl")
include("trees.jl")
include("conllu.jl")

include("treebanks.jl")

include("transition_parsing/systems.jl")
include("transition_parsing/oracles.jl")

include("evaluation/accuracy.jl")

end # module
