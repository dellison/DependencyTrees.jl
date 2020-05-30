using DependencyTrees
using DependencyTrees.TransitionParsing
using Documenter

DocMeta.setdocmeta!(DependencyTrees, :DocTestSetup, :(using DependencyTrees); recursive=true)

makedocs(
    sitename = "DependencyTrees.jl",
    format = Documenter.HTML(),
    modules = [DependencyTrees],
    pages = [
        "Home" => "index.md",
        "Trees" => ["trees.md", "treebanks.md"],
        "Transition Parsing" => "transition_parsing.md",
        "Evaluation" => "evaluation.md",
        "Errors" => "errors.md"
    ],
    doctest = true
)

deploydocs(repo = "github.com/dellison/DependencyTrees.jl.git")
