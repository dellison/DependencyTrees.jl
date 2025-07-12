"""
    Treebank

A reader for a file with annotated parse trees.
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

