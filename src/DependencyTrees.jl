module DependencyTrees

export
    DependencyGraph,
    LabeledDependency,
    TypedDependency,
    UntypedDependency

using LightGraphs

include("errors.jl")
include("dependencies.jl")
include("graphs.jl")



end # module
