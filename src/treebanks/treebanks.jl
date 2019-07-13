include("reader.jl")

struct Treebank{T<:Dependency}
    files::Vector{String}
    add_id::Bool
    allow_nonprojective::Bool
    allow_multiheaded::Bool
end

"""
    Treebank{T}(treebank; pattern=r".", add_ad=false, allow_nonprojective=false,kwargs...) whereT

Create a treebank from a `treebank` directory from files matching `pattern`.
"""
function Treebank{T}(treebank::String; pattern = r".", add_id=false,
                     allow_nonprojective=true, allow_multiheaded=true) where T
    if isfile(treebank)
        Treebank{T}([treebank], add_id, allow_nonprojective, allow_multiheaded)
    elseif isdir(treebank)
        treebank_files = String[]
        for (root, dirs, files) in walkdir(treebank), file in files
            if occursin(pattern, file)
                push!(treebank_files, joinpath(root, file))
            end
        end
        Treebank{T}(treebank_files, add_id, allow_nonprojective, allow_multiheaded)
    else
        error("Couldn't read '$treebank'")
    end
end

"""
    Treebank{T}(files; add_id=false, allow_nonprojective=false, kwargs...)

Create a treebank from `files`.
"""
function Treebank{T}(files::Vector{String}; add_id=false, allow_nonprojective=true, allow_multiheaded=true, kwargs...) where T
    Treebank{T}(files, add_id, allow_nonprojective, allow_multiheaded)
end

function Treebank(treebank; kwargs...)
    endswith(treebank, ".conllu") ? Treebank{CoNLLU}(treebank; kwargs...) :
        endswith(treebank, "conll") ? Treebank{CoNLLU}(treebank; kwargs...) :
        error("error reading '$treebank'")
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

function Base.show(io::IO, treebank::Treebank)
    T = deptype(treebank)
    len = length(treebank.files)
    print(io, "Treebank{$T} of $len file(s)")
end

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
    if !t.t.allow_nonprojective && !isprojective(graph)
        return iterate(t, (state, 1))
    end
    return (graph, (state, 1))
end
function Base.iterate(t::TreebankIterator, state)
    next = iterate(t.reader, state)
    if next != nothing
        (graph, (st, i)) = next
        if !t.t.allow_nonprojective && !isprojective(graph)
            return iterate(t, (st, i+1))
        end
        return (graph, (st, i+1))
    else
        if t.i < length(t.t.files)
            t.i += 1
            t.reader = TreebankReader{deptype(t.t)}(t.t.files[t.i]; allow_nonprojective=t.t.allow_nonprojective, allow_multiheaded=t.t.allow_multiheaded)
            graph, state = iterate(t.reader)
            return (graph, (state, 1))
        else
            return nothing
        end
    end
end

Base.IteratorSize(t::TreebankIterator) = Base.SizeUnknown()
