abstract type DependencyTreeError <: Exception end

"""
    NonProjectiveGraphError

Error trying to parse a nonprojective tree with a projective only algorithm.
"""
struct NonProjectiveGraphError <: DependencyTreeError
    tree
end

"""
    MultiWordTokenError

Error for a multi-token annotation that isn't part of the tree.
"""
struct MultiWordTokenError <: DependencyTreeError
    token
end

"""
    EmptyTokenError

Error for an empty token annotation that isn't part of the tree.
"""
struct EmptyTokenError <: DependencyTreeError
    token
end
