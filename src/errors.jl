abstract type DependencyTreeError <: Exception end

"""
    NonProjectiveGraphError

todo
"""
struct NonProjectiveGraphError <: DependencyTreeError
    tree
end

"""
    RootlessGraphError

todo
"""
struct RootlessGraphError <: DependencyTreeError
    tree
end

"""
    MultipleRootsError

todo
"""
struct MultipleRootsError <: DependencyTreeError
    tree
end

"""
    MultiWordTokenError

todo
"""
struct MultiWordTokenError <: DependencyTreeError
    token
end

"""
    EmptyTokenError

todo
"""
struct EmptyTokenError <: DependencyTreeError
    token
end
