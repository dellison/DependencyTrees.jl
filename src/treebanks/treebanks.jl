include("reader.jl")

"""
    Treebank{T<:Dependency}

A lazily-accessed corpus of dependency trees.

Treebank{CoNLLU}("/path/to/treebank")

Treebank{CoNLLU}(["file1", "file2", ...])
"""
struct Treebank{T<:Dependency}
    files::Vector{String}
    add_id::Bool
    remove_nonprojective::Bool
    kwargs
end

function Treebank{T}(file_or_dir::String; pattern = r".", add_id=false,
                     remove_nonprojective=false, kwargs...) where T
    if isfile(file_or_dir)
        Treebank{T}([file_or_dir], add_id, remove_nonprojective, kwargs)
    elseif isdir(file_or_dir)
        treebank_files = String[]
        for (root, dirs, files) in walkdir(file_or_dir), file in files
            if occursin(pattern, file)
                push!(treebank_files, joinpath(root, file))
            end
        end
        Treebank{T}(treebank_files, add_id, remove_nonprojective, kwargs)
    else
        error("don't know how to read '$file_or_dir' as a treebank")
    end
end

function Treebank{T}(files::Vector{String}; add_id=false, remove_nonprojective=false, kwargs...) where T
    Treebank{T}(files, add_id, remove_nonprojective, kwargs)
end

deptype(::Type{<:Treebank{T}}) where T = T
deptype(treebank::Treebank) = deptype(typeof(treebank))

trees(treebank::Treebank) = TreebankIterator(treebank)

function Base.iterate(treebank::Treebank)
    iter = TreebankIterator(treebank)
    graph, state = iterate(iter)
    return (graph, (iter, state))
end
function Base.iterate(treebank::Treebank, state)
    (iter, st) = state
    next = iterate(iter, st)
    if next == nothing
        return nothing
    else
        graph, next_state = next
        return (graph, (iter, next_state))
    end
end
    
Base.IteratorSize(treebank::Treebank) = Base.SizeUnknown()

Base.length(treebank::Treebank) = length(collect(treebank))

mutable struct TreebankIterator{T}
    t::Treebank{T}
    i::Int
    reader::TreebankReader
end

function TreebankIterator(tb::Treebank)
    r = TreebankReader{deptype(tb)}(first(tb.files), add_id=tb.add_id)
    TreebankIterator(tb, 1, r)
end

function Base.iterate(t::TreebankIterator)
    graph, state = iterate(t.reader)
    if t.t.remove_nonprojective && !isprojective(graph)
        return iterate(t, (state, 1))
    end
    return (graph, (state, 1))
end
function Base.iterate(t::TreebankIterator, state)
    next = iterate(t.reader, state)
    if next != nothing
        (graph, (st, i)) = next
        if t.t.remove_nonprojective && !isprojective(graph)
            return iterate(t, (st, i+1))
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
