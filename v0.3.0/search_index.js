var documenterSearchIndex = {"docs":
[{"location":"transition_parsing/#Transition-Parsing-1","page":"Transition Parsing","title":"Transition Parsing","text":"","category":"section"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"The TransitionParsing submodule provides implementations of transition-based parsing algorighms.","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"julia> using DependencyTrees.TransitionParsing","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"In transition-based dependency parsing, trees are built incrementally and greedily, one relation at a time. Transition systems define an intermediate parser state (or configuration), and oracles map confifurations to \"gold\" transitions.","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"The DependencyTrees.TransitionParsing module implements the following transition systems:","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Arc-Standard\nArc-Eager\nArc-Hybrid\nArc-Swift\nList-Based Non-Projective","category":"page"},{"location":"transition_parsing/#Arc-Standard-1","page":"Transition Parsing","title":"Arc-Standard","text":"","category":"section"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"ArcStandard","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.ArcStandard","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.ArcStandard","text":"ArcStandard()\n\nTransition system for for Arc-Standard dependency parsing.\n\nTransitions\n\nTransition Definition\nLeftArc(l) (σ|s1|s0, β, A) → (σ|s0, β, A ∪ (s0, l, s1))\nRightArc(l) (σ|s, b|β, A) → (σ, b|β, A ∪ (b, l, s))\nShift (σ,  b|β, A) → (σ|b, β, A)\n\nPreconditions\n\nTransition Condition\nLeftArc(l) ¬[s1 = 0], ¬∃k∃l'[(k, l', s1) ϵ A]\nRightArc(l) ¬∃k∃l'[(k, l', s0) ϵ A]\n\nSee Nivre 2004.\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Oracle function for arc-standard parsing:","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"static_oracle(::TransitionParsing.ArcStandardConfig, tree, arc=untyped)","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.static_oracle","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.static_oracle","text":"static_oracle(cfg, gold_tree)\n\nStatic oracle function for arc-standard dependency parsing.\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#Arc-Eager-1","page":"Transition Parsing","title":"Arc-Eager","text":"","category":"section"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"ArcEager","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.ArcEager","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.ArcEager","text":"ArcEager()\n\nArc-Eager transition system for dependency parsing.\n\nTransitions\n\nTransition Definition\nLeftArc(l) (σ|s, b|β, A) → (σ, b|β, A ∪ (b, l, s))\nRightArc(l) (σ|s, b|β, A) → (σ, b|β, A ∪ (b, l, s))\nReduce (σ|s, β,  A) → (σ, β,   A)\nShift (σ,  b|β, A) → (σ|b, β, A)\n\nPreconditions\n\nTransition Condition\nLeftArc(l) ¬[s = 0], ¬∃k∃l'[(k, l', i) ϵ A]\nRightArc(l) ¬∃k∃l'[(k, l', j) ϵ A]\nReduce ∃k∃l[(k, l, i) ϵ A]\n\nReferences\n\nNivre 2003, Nivre 2008.\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Oracle functions for arc-eager parsing:","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"static_oracle(::TransitionParsing.ArcEagerConfig, tree, arc=untyped)\nstatic_oracle_prefer_shift(::TransitionParsing.ArcEagerConfig, tree, arc=untyped)\ndynamic_oracle(cfg::TransitionParsing.ArcEagerConfig, tree, arc=untyped)","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.static_oracle","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.static_oracle","text":"static_oracle(cfg::ArcEagerConfig, gold, arc=untyped)\n\nDefault static oracle function for arc-eager dependency parsing.\n\nSee Goldberg & Nivre 2012. (Also called Arc-Eager-Reduce in Qi & Manning 2017).\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.static_oracle_prefer_shift","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.static_oracle_prefer_shift","text":"static_oracle_prefer_shift(cfg::ArcEagerConfig, tree, arc=untyped)\n\nStatic oracle for arc-eager dependency parsing. Similar to the \"regular\" static oracle, but always Shift when ambiguity is present.\n\nSee Qi & Manning 2017.\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.dynamic_oracle","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.dynamic_oracle","text":"dynamic_oracle(cfg::ArgEagerConfig, tree, arc=untyped)\n\nDynamic oracle function for arc-eager parsing.\n\nFor details, see Goldberg & Nivre 2012.\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#Arc-Hybrid-1","page":"Transition Parsing","title":"Arc-Hybrid","text":"","category":"section"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"ArcHybrid","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.ArcHybrid","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.ArcHybrid","text":"ArcHybrid()\n\nArc-Hybrid system for transition dependency parsing.\n\nDescribed in Kuhlmann et al, 2011, Goldberg & Nivre, 2013.\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Oracle functions for arc-hybrid parsing:","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"static_oracle(::TransitionParsing.ArcHybridConfig, tree, arc=untyped)\ndynamic_oracle(::TransitionParsing.ArcHybridConfig, tree, arc)","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.static_oracle","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.static_oracle","text":"static_oracle(cfg::ArcHybridConfig, tree, arc=untyped)\n\nStatic oracle for arc-hybrid dependency parsing.\n\nReturn a gold transition (one of LeftArc, RightArc, or Shift) for parser configuration cfg.\n\nSee Kuhlmann et al, 2011?\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.dynamic_oracle-Tuple{DependencyTrees.TransitionParsing.ArcHybridConfig,Any,Any}","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.dynamic_oracle","text":"dynamic_oracle(cfg::ArgHybridConfig, tree, arc)\n\nDynamic oracle function for arc-hybrid parsing.\n\nFor details, see Goldberg & Nivre, 2013.\n\n\n\n\n\n","category":"method"},{"location":"transition_parsing/#Arc-Swift-1","page":"Transition Parsing","title":"Arc-Swift","text":"","category":"section"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"ArcSwift","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.ArcSwift","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.ArcSwift","text":"ArcSwift()\n\nArc-Swift transition system for dependency parsing.\n\nDescribed in Qi & Manning 2017.\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Oracle function for arc-swift parsing:","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"static_oracle(::TransitionParsing.ArcSwiftConfig, gold, arc=untyped)","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.static_oracle","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.static_oracle","text":"static_oracle(cfg::ArcSwiftConfig, tree, arc)\n\nOracle function for arc-swift dependency parsing.\n\nDescribed in Qi & Manning 2017.\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#List-Based-Non-Projective-1","page":"Transition Parsing","title":"List-Based Non-Projective","text":"","category":"section"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"ListBasedNonProjective","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.ListBasedNonProjective","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.ListBasedNonProjective","text":"ListBasedNonProjective()\n\nTransition system for list-based non-projective dependency parsing.\n\nDescribed in Nivre 2008, \"Algorithms for Deterministic Incremental Dependency Parsing.\"\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Oracle function for list-based non-projective parsing:","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"static_oracle(::TransitionParsing.ListBasedNonProjectiveConfig, tree, arc=untyped)","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.static_oracle","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.static_oracle","text":"static_oracle(::ListBasedNonProjectiveConfig, tree)\n\nReturn a training oracle function which returns gold transition operations from a parser configuration with reference to graph.\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"<!– ## Misc. –>","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"<!– For stack-and-buffer transition systems (Arc-Eager, Arc-Standard, Arc-Hybrid, and Arc-Swift), DependencyTrees.jl implements functions for getting the tokens from the stack and buffer in a safe way: –>","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"<!– @docs --> <!-- stacktoken --> <!-- buffertoken --> <!-- –>","category":"page"},{"location":"transition_parsing/#Oracles-1","page":"Transition Parsing","title":"Oracles","text":"","category":"section"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"An Oracle maps a parser configuration to one more gold transitions, which can be used to train a dependency parser.","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Oracle","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.Oracle","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.Oracle","text":"Oracle(system, oracle_function; label=untyped)\n\nCreate an oracle for predicting gold transitions in dependency parsing.\n\nsystem is a transition system, defining configurations and valid transitions.\n\noracle_function is called on a paraser configuration and tree for gold predictions:\n\noracle(cfg, tree, label)\n\nlabel is a function that's called on the gold tokens for that parameters of arcs.\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"An oracle acts like a function when called on a DependencyTree, returning either an OracleSequence or an UnparsableTree in the case when a tree cannot be parsed.","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"TransitionParsing.OracleSequence\nTransitionParsing.UnparsableTree","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.OracleSequence","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.OracleSequence","text":"OracleSequence(oracle, tree, policy=NeverExplore())\n\nA \"gold\" sequence of parser configurations and transitions to build tree.\n\nThe sequence of transitions is performed according to\n\npolicy is a function that determines whether or not \"incorrect\" transitions are explored. It will be called like so: `policy(\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.UnparsableTree","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.UnparsableTree","text":"UnparsableTree\n\nA dependency tree that an oracle cannot parse.\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"An Oracle's third argument is a function called on a DependencyTrees.Token to parametrize a transition. This parameterization can be arbitrary, but DependencyTrees.TransitionParsing exports two function which yield labeled or unlabeled dependencies, respectively:","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"untyped\ntyped","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.untyped","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.untyped","text":"untyped(token)\n\nCreate an arc without a dependency label.\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.typed","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.typed","text":"typed(token)\n\nCreate an arc with a labeled dependency relation.\n\n\n\n\n\n","category":"function"},{"location":"transition_parsing/#Exploration-Policies-1","page":"Transition Parsing","title":"Exploration Policies","text":"","category":"section"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Training a parser on only optimal sequeces of transitions can result in poor decisions under suboptimal conditions (i.e., after a mistake has been made). To compensate for this, OracleSequences can be created with exploration policies to control when (if ever) a \"wrong\" transition that prevents the correct parse from being produced is allowed.","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"Exploration policies can wrap a model, which will be called to predict a transition (called like model(cfg, A, G) where cfg is the parser configuration, A is a vector of possible transitions, and G is the gold transition(s) according to the oracle function). The exploration policy then selects the next transition from A and G and the prediction, if available.","category":"page"},{"location":"transition_parsing/#","page":"Transition Parsing","title":"Transition Parsing","text":"AlwaysExplore\nNeverExplore\nExplorationPolicy","category":"page"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.AlwaysExplore","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.AlwaysExplore","text":"AlwaysExplore()\n\nPolicy for always exploring sub-optimal transitions.\n\nIf model predicts a legal transition, apply it. Otherwise, sample from the possible transitions (without regard to the oracle transitions) according to rng.\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.NeverExplore","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.NeverExplore","text":"NeverExplore()\n\nPolicy for never exploring sub-optimal transitions.\n\nIf model predicts a gold transition, apply it. Otherwise, choose from the gold transitions according to rng.\n\n\n\n\n\n","category":"type"},{"location":"transition_parsing/#DependencyTrees.TransitionParsing.ExplorationPolicy","page":"Transition Parsing","title":"DependencyTrees.TransitionParsing.ExplorationPolicy","text":"ExplorationPolicy(k, p)\n\nSimple exploration policy from Goldberg & Nivre, 2012. Explores at rate p.\n\nWith rate p, follow model's prediction if legal, or choose from the possible transitions according to rng if the prediction can't be followed. With probability 1 -p, choose from gold transitions according to rng.\n\n\n\n\n\n","category":"type"},{"location":"treebanks/#Treebanks-1","page":"Treebanks","title":"Treebanks","text":"","category":"section"},{"location":"treebanks/#","page":"Treebanks","title":"Treebanks","text":"A Treebank is a corpus of dependency-annotated sentences in one or more files.","category":"page"},{"location":"treebanks/#","page":"Treebanks","title":"Treebanks","text":"Treebank","category":"page"},{"location":"treebanks/#DependencyTrees.Treebank","page":"Treebanks","title":"DependencyTrees.Treebank","text":"Treebank\n\nA corpus of sentences annotated as dependency trees on disk.\n\n\n\n\n\n","category":"type"},{"location":"treebanks/#","page":"Treebanks","title":"Treebanks","text":"Iterating over a treebank reads sentences one at a time:","category":"page"},{"location":"treebanks/#","page":"Treebanks","title":"Treebanks","text":"treebank = Treebank(\"data/news.conll\")\n\nfor tree in treebank\n    # ...\nend\n\ntree = first(treebank)\n\n# output\n┌────────────── ROOT\n│           ┌─► Economic\n│        ┌─►└── news\n└─►┌──┌──└───── had\n   │  │     ┌─► little\n   │  └─►┌──└── effect\n   │  ┌──└────► on\n   │  │     ┌─► financial\n   │  └────►└── markets\n   └──────────► .","category":"page"},{"location":"trees/#Trees-1","page":"Trees","title":"Trees","text":"","category":"section"},{"location":"trees/#","page":"Trees","title":"Trees","text":"Dependency structure in natural language consists of directed relations between words in a sentence.","category":"page"},{"location":"trees/#","page":"Trees","title":"Trees","text":"Simple API for building dependency trees:","category":"page"},{"location":"trees/#","page":"Trees","title":"Trees","text":"deptree\ndeptoken","category":"page"},{"location":"trees/#DependencyTrees.deptree","page":"Trees","title":"DependencyTrees.deptree","text":"deptree(read_token, xs)\n\nCreate a DependencyTree by calling read_token on each of xs.\n\n\n\n\n\n","category":"function"},{"location":"trees/#DependencyTrees.deptoken","page":"Trees","title":"DependencyTrees.deptoken","text":"deptoken(form, head=-1, label=nothing)\n\nCreate a token in a dependency tree.\n\n\n\n\n\n","category":"function"},{"location":"trees/#","page":"Trees","title":"Trees","text":"DependencyTree","category":"page"},{"location":"trees/#DependencyTrees.DependencyTree","page":"Trees","title":"DependencyTrees.DependencyTree","text":"DependencyTree\n\nA rooted tree of dependency relations among the tokens of a sentence.\n\n\n\n\n\n","category":"type"},{"location":"errors/#Errors-1","page":"Errors","title":"Errors","text":"","category":"section"},{"location":"errors/#","page":"Errors","title":"Errors","text":"DependencyTrees.MultiWordTokenError\nDependencyTrees.NonProjectiveGraphError\nDependencyTrees.EmptyTokenError","category":"page"},{"location":"errors/#DependencyTrees.MultiWordTokenError","page":"Errors","title":"DependencyTrees.MultiWordTokenError","text":"MultiWordTokenError\n\nError for a multi-token annotation that isn't part of the tree.\n\n\n\n\n\n","category":"type"},{"location":"errors/#DependencyTrees.NonProjectiveGraphError","page":"Errors","title":"DependencyTrees.NonProjectiveGraphError","text":"NonProjectiveGraphError\n\nError trying to parse a nonprojective tree with a projective only algorithm.\n\n\n\n\n\n","category":"type"},{"location":"errors/#DependencyTrees.EmptyTokenError","page":"Errors","title":"DependencyTrees.EmptyTokenError","text":"EmptyTokenError\n\nError for an empty token annotation that isn't part of the tree.\n\n\n\n\n\n","category":"type"},{"location":"#DependencyTrees.jl-1","page":"Home","title":"DependencyTrees.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"DependencyTrees.jl is a julia package for working with natural language dependency structures.","category":"page"},{"location":"#Overview-1","page":"Home","title":"Overview","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"In the study of natural language, the dependency relation defines a directed relationship between words in a sentence. The DependencyTrees.jl package is for working with natural language data annotated with dependency relations, where each sentence forms a tree.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"The TransitionParsing submodule implements some algorithms for transision-based dependency parsing.","category":"page"},{"location":"#Installation-1","page":"Home","title":"Installation","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"DependencyTrees is a registered Julia package, and can be installed with Julia's built-in package manager:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> ]add DependencyTrees\njulia> using DependencyTrees","category":"page"},{"location":"evaluation/#Evaluation-1","page":"Evaluation","title":"Evaluation","text":"","category":"section"},{"location":"evaluation/#","page":"Evaluation","title":"Evaluation","text":"labeled_accuracy\nunlabeled_accuracy","category":"page"},{"location":"evaluation/#DependencyTrees.labeled_accuracy","page":"Evaluation","title":"DependencyTrees.labeled_accuracy","text":"labeled_accuracy(prediction, gold)\n\nAccuracy score for dependency arcs, including the labels.\n\n\n\n\n\n","category":"function"},{"location":"evaluation/#DependencyTrees.unlabeled_accuracy","page":"Evaluation","title":"DependencyTrees.unlabeled_accuracy","text":"unlabeled_accuracy(prediction, gold)\n\nAccuracy score for dependency arcs, not including the labels.\n\n\n\n\n\n","category":"function"}]
}
