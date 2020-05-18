# TODO ids?
# TODO docs
# TODO comments
# TODO multi word tokens
# TODO empty tokens
# TODO skip malformed trees?

struct Treebank{F}
    files::Vector{String}
    read_token::F
end

Treebank(file::String, read_token) = Treebank([file], read_token)

Treebank(file::String) = Treebank([file])
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

Base.show(io::IO, tb::Treebank) =
    print(io, "Treebank ($(length(tb.files)) files)")

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
    # lines = [line for line in split(strip(str), "\n") if !startswith(line, "#")]
    return deptree(str, trees.read_token)
end

function Base.iterate(tr::TreeReader, state=nothing)
    tree = read_tree(tr)
    tree === nothing ? nothing : (tree, nothing)
end
