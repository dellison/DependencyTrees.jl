include("reader.jl")

"""
    Treebank{T<:Dependency}

A lazily-accessed corpus of dependency trees.
"""
struct Treebank{T<:Dependency}
    files::Vector{String}
    kwargs

    Treebank{T}(files; kwargs...) where T = new{T}(files, kwargs)
end

function Treebank{T}(file_or_dir::String; pattern = r".", kwargs...) where T
    if isfile(file_or_dir)
        Treebank{T}([file_or_dir]; kwargs...)
    elseif isdir(file_or_dir)
        treebank_files = String[]
        for (root, dirs, files) in walkdir(file_or_dir), file in files
            if occursin(pattern, file)
                push!(treebank_files, joinpath(root, file))
            end
        end
        Treebank{T}(treebank_files; kwargs...)
    else
        error("don't know how to read '$file_or_dir' as a treebank")
    end
end

deptype(::Type{<:Treebank{T}}) where T = T
deptype(g::Treebank) = deptype(typeof(g))

trees(treebank::Treebank) = TreebankIterator(treebank)

function Base.iterate(t::Treebank)
    iter = TreebankIterator(t)
    graph, state = iterate(iter)
    return (graph, (iter, state))
end
function Base.iterate(t::Treebank, state)
    (iter, st) = state
    next = iterate(iter, st)
    if next == nothing
        return nothing
    else
        graph, next_state = next
        return (graph, (iter, next_state))
    end
end
    
Base.IteratorSize(t::Treebank) = Base.SizeUnknown()



mutable struct TreebankIterator{T}
    t::Treebank{T}
    i::Int
    reader::TreebankReader
end

TreebankIterator(t::Treebank) =
    TreebankIterator(t, 1, TreebankReader{deptype(t)}(first(t.files)))

function Base.iterate(t::TreebankIterator)
    graph, state = iterate(t.reader)
    if :remove_nonprojective in keys(t.t.kwargs)
        if t.t.kwargs[:remove_nonprojective] && !isprojective(graph)
            return iterate(t, (state, 1))
        end
    end
    return (graph, (state, 1))
end
function Base.iterate(t::TreebankIterator, state)
    next = iterate(t.reader, state)
    if next != nothing
        (graph, (st, i)) = next
        if :remove_nonprojective in keys(t.t.kwargs)
            if t.t.kwargs[:remove_nonprojective] && !isprojective(graph)
                return iterate(t, (st, i+1))
            end
        end
        return (graph, (st, i+1))
    else
        if t.i < length(t.t.files)
            t.i += 1
            t.reader = TreebankReader{deptype(t.t)}(t.t.files[t.i])
            graph, state = iterate(t.reader)
            return (graph, (state, 1))
        else
            return nothing
        end
    end
end

Base.IteratorSize(t::TreebankIterator) = Base.SizeUnknown()
