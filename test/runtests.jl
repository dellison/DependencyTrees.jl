using DependencyTrees, Test

const DT = DependencyTrees

using DependencyTrees: TreebankReader
using DependencyTrees: projective_only, deptype
using DependencyTrees: deprel, form, id, hashead, head, root, isroot
using DependencyTrees: MultiWordTokenError, EmptyTokenError
using DependencyTrees: stack, buffer, stacklength, bufferlength
using DependencyTrees: leftmostdep, rightmostdep
using DependencyTrees: leftdeps, rightdeps
using DependencyTrees: root, noval, token, tokens, xys

using DependencyTrees: typed, untyped
using DependencyTrees: initconfig, transition_space
using DependencyTrees: leftarc, rightarc, noarc, shift, isfinal
using DependencyTrees: LeftArc, RightArc, NoArc, Reduce, Shift
using DependencyTrees: gold_transitions

function showstr(op)
    buf = IOBuffer()
    show(buf, op)
    return String(take!(buf))
end

function test_treebank(filename)
    Treebank{CoNLLU}(joinpath(@__DIR__, "data", filename))
end

function test_sentence(filename)
    first(test_treebank(filename))
end

@testset "DependencyTrees" begin 
    include("test_tokens.jl")
    include("test_graphs.jl")
    include("test_slp3_ch13.jl")
    include("test_nivre08.jl")
    include("test_kubleretal09.jl")
    include("test_treebanks.jl")
    include("test_conllu.jl")
    include("test_dynamic.jl")
    include("test_arc_hybrid.jl")
    include("test_arc_swift.jl")
    include("test_evaluation.jl")
end
