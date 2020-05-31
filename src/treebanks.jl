# TODO ids?
# TODO docs
# TODO comments
# TODO multi word tokens
# TODO empty tokens
# TODO skip malformed trees?
"""
    Treebank

A corpus of sentences annotated as dependency trees on disk.
"""
struct Treebank{F}
    files::Vector{String}
    read_token::F
end

"""
    Treebank(file::String, read_token)

Read treebank from file `file`, calling `read_token` on each line to read tokens.
"""
Treebank(file::String, read_token) = Treebank([file], read_token)

"""
    Treebank(file)

Read a treebank from `files`, detecting the format from the filenames.
"""
Treebank(file::String) = Treebank([file])

"""
    Treebank(files)

Read a treebank from the files `files`, attempting to detect the format.
"""
function Treebank(files::Vector{String})
    if all(file -> endswith(file, ".conllu") || endswith(file, ".conll"), files)
        Treebank(files, from_conllu)
    else
        error("don't know how to read $files")
    end
end

function Base.iterate(tb::Treebank)
    r = TreeReader(first(tb.files), tb.read_token)
    return iterate(tb, (r, 1))
end
function Base.iterate(tb::Treebank, state)
    r, i = state
    tree = read_tree(r)
    if tree === nothing
        if i < length(tb.files)
            j = i + 1
            return iterate(tb, (TreeReader(tb.files[j], tb.read_token), j))
        end
    else
        return tree, state
    end
end

function Base.show(io::IO, tb::Treebank)
    fs = length(tb.files)
    len_str = length(tb.files) == 1 ? "1 file" : "$fs files"
    print(io, "Treebank ($len_str)")
end

Base.IteratorSize(treebank::Treebank) = Base.SizeUnknown()

struct TreeReader
    io::IO
    read_token
end

TreeReader(file::String, read_token) = TreeReader(open(file), read_token)

function read_tree(trees::TreeReader)
    io = trees.io
    if eof(io)
        close(io)
        return nothing
    end
    str = readuntil(io, "\n\n")
    return deptree(str, trees.read_token)
end
