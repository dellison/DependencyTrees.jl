module DependencyTrees

export
    DependencyGraph,
    Dependency, TypedDependency, UntypedDependency

using LightGraphs

include("errors.jl")
include("dependencies.jl")
include("graphs.jl")
include("parse/parse.jl")

end # module
