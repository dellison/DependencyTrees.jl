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

# TODO add support for multi-word tokens and remove this
struct MultiWordTokenError <: DependencyTreeError
end

# TODO add support for empty nodes and remove this
struct EmptyNodeError <: DependencyTreeError
end
