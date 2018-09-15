abstract type DependencyTreeError <: Exception end

struct GraphConnectivityError <: DependencyTreeError
    g
    msg::String
end

struct NonProjectiveGraphError <: DependencyTreeError
    g
end

struct RootlessGraphError <: DependencyTreeError
    g
end

struct MultipleRootsError <: DependencyTreeError
    g
end

struct MultiWordTokenError <: DependencyTreeError end

struct EmptyTokenError <: DependencyTreeError end
