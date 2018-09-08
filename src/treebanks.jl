
mutable struct TreebankReader{T<:Dependency}
    io::IO
    lineno::Int
    comment_rx::Regex
    add_id::Bool
    kwargs
end

"""
    TreebankReader{Dependency}

Read trees from a file.
"""
function TreebankReader{T}(file::String; comment_rx=r"^#", add_id=false, kwargs...) where T
    TreebankReader{T}(open(file), 1, comment_rx, add_id, kwargs)
end

function TreebankReader{T}(io::IO; comment_rx=r"^#", kwargs...) where T
    TreebankReader{T}(io, 1, comment_rx, add_id, kwargs)
end

Base.iterate(t::TreebankReader) = iterate(t, 1)

function Base.iterate(t::TreebankReader, state)
    T = deptype(t)
    tokens = T[]
    newl = false
    i = t.lineno
    while isopen(t.io) && !newl
        i += 1
        line = readline(t.io)
        if occursin(t.comment_rx, line)
            continue
        elseif isempty(line)
            if !newl
                newl = true
            else
                break
            end
        else
            if t.add_id
                push!(tokens, T(length(tokens) + 1, String(line); t.kwargs...))
            else
                push!(tokens, T(String(line); t.kwargs...))
            end
        end
    end
    t.lineno = i
    if length(tokens) == 0
        close(t.io)
        return nothing
    else
        return (DependencyGraph(tokens; t.kwargs...), state)
    end
end

deptype(::Type{<:TreebankReader{T}}) where T = T
deptype(g::TreebankReader) = deptype(typeof(g))

function Base.collect(t::TreebankReader)
    T = deptype(t)
    trees = DependencyGraph{T}[]
    for tree in t
        push!(trees, tree)
    end
    return trees
end
