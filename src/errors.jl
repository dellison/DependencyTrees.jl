abstract type DependencyTreeError <: Exception end

struct GraphConnectivityError <: DependencyTreeError
    g
    msg::String
end

struct RootlessGraphError <: DependencyTreeError
    g
end

struct MultipleRootsError <: DependencyTreeError
    g
end
