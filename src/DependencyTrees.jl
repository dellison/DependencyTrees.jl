module DependencyTrees

export
    DependencyTree, isprojective,
    Treebank,
    TypedDependency, UntypedDependency, CoNLLU,

    # Transition parsing
    ArcEager, ArcStandard, ArcHybrid, ArcSwift, ListBasedNonProjective,
    StaticOracle, DynamicOracle, static_oracle, static_oracle_shift

using Random
using LightGraphs

import Base.==
import Base.getindex

include("errors.jl")
include("dependencies.jl")
include("conllu.jl")
include("trees.jl")

include("treebanks/treebanks.jl")

include("graph_parsing/parse.jl")
include("transition_parsing/parse.jl")

include("evaluation/accuracy.jl")

end # module
