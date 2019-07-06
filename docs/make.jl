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

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
