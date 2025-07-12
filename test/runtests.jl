using DependencyTrees
using Test

using DependencyTrees.TransitionParsing

const DT = DependencyTrees

using DependencyTrees: MultiWordTokenError, EmptyTokenError
using DependencyTrees: leftdeps, rightdeps, leftmostdep, rightmostdep
using DependencyTrees.TransitionParsing: stack, buffer, token, tokens


function showstr(op)
    buf = IOBuffer()
    show(buf, op)
    return String(take!(buf))
end

function test_treebank(filename, parse=conllu)
    Treebank(joinpath(@__DIR__, "data", filename), parse)
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
    include("test_arc_standard.jl")
    include("test_arc_swift.jl")
    include("test_evaluation.jl")
end
