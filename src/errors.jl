abstract type DependencyTreeError <: Exception end

struct GraphConnectivityError <: DependencyTreeError
    g::DependencyGraph
    msg::String
end

struct RootlessGraphError <: DependencyTreeError
    g::DependencyGraph
end

struct MultipleRootsError <: DependencyTreeError
    g::DependencyGraph
end
