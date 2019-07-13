using Documenter
using DependencyTrees

makedocs(
    sitename = "DependencyTrees.jl",
    format = Documenter.HTML(),
    modules = [DependencyTrees],
    pages = ["Home" => "index.md",
             "Trees" =>
             ["trees.md", "treebanks.md"],
             "Transition Parsing" =>
             ["oracles.md", "transition_parsing.md"],
             "Evaluation" => "evaluation.md"],
    doctest = true)

deploydocs(repo = "github.com/dellison/DependencyTrees.jl.git")
