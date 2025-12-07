"""
    Treebank

A reader for a file containing annotated dependency parse trees.

Iterating (i.e., using a for-loop) produces one tree at a time. The
tree is produced by first calling the treebank's `read_sentence`
field, and then the `parse` field is called to parse the serialized
representation into a `DependencyTree`.
"""
struct Treebank{S,F}
    file::String
    read_sentence::S
    parse::F
end

function Treebank(file)
    if endswith(file, ".conllu")
        return Treebank(file, readuntilemptyline, conllu)
    elseif endswith(file, ".conllx")
        return Treebank(file, readuntilemptyline, conllx)
    else
        error("don't know how to parse $file")
    end
end

Treebank(file, parse) = Treebank(file, readuntilemptyline, parse)

function Base.iterate(tb::Treebank)
    state = open(tb.file)
    return iterate(tb, state)
end

function Base.iterate(tb::Treebank, state)
    if eof(state)
        close(state)
        return nothing
    end
    sentence = tb.read_sentence(state)
    tree = tb.parse(sentence)
    return tree, state
end

readuntilemptyline(io) = readuntil(io, "\n\n")

Base.IteratorSize(tb::Treebank) = Base.SizeUnknown()
