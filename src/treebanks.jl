
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
    TreebankReader{T}(open(file), 0, comment_rx, add_id, kwargs)
end

function TreebankReader{T}(io::IO; comment_rx=r"^#", kwargs...) where T
    TreebankReader{T}(io, 0, comment_rx, add_id, kwargs)
end

Base.iterate(t::TreebankReader) = iterate(t, 1)

function Base.iterate(t::TreebankReader, state)
    T = deptype(t)
    tokens, mwts, emptytokens = T[], MultiWordToken[], EmptyToken[]
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
            try
                if t.add_id
                    push!(tokens, T(length(tokens) + 1, String(line); t.kwargs...))
                else
                    push!(tokens, T(String(line); t.kwargs...))
                end
            catch err
                if isa(err, MultiWordTokenError)
                    push!(mwts, MultiWordToken(line))
                elseif isa(err, EmptyTokenError)
                    push!(emptytokens, EmptyToken(line))
                end
                continue
            end
        end
    end
    t.lineno = i
    if length(tokens) == 0
        close(t.io)
        return nothing
    else
        return (DependencyGraph(tokens; mwts=mwts, emptytokens=emptytokens, t.kwargs...), state)
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

struct Treebank{T<:Dependency}
    files::Vector{String}
    kwargs

    Treebank{T}(files; kwargs...) where T = new{T}(files, kwargs)
end

Treebank{T}(file::String; kwargs...) where T = Treebank{T}([file]; kwargs...)

deptype(::Type{<:Treebank{T}}) where T = T
deptype(g::Treebank) = deptype(typeof(g))
