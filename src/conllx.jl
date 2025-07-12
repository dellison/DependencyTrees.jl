# CoNLL-X format

"""
    conllx(text)

Read a dependency tree from text (in CoNLL-X format).

See: https://aclanthology.org/W06-2920.pdf
"""
function conllx(text::AbstractString)
    tokens = Token[]
    for line in split(text, "\n")
        # comments?
        columns = split(strip(line), "\t")
        @assert length(columns) == 10
        # first column: ID
        # token counter, starting at 1 for each new sentence
        id = parse(Int, columns[1])
        form, lemma, cpostag, postag = String.(columns[2:5])

        # col 6: FEATS
        # Unordered set of syntactic and/or morphological features
        # (depending on the particu- lar treebank), or an underscore
        # if not available. Set members are separated by a vertical
        # bar (|).
        feats_ = columns[6]
        feats = feats_ == "_" ? String[] : String.(split(feats_, "|"))

        # col 7: HEAD
        # head of the current token, which is either a value of ID, or
        # zero (’0’) if the token links to the virtual root node of
        # the sentence. Note that depending on the original treebank
        # annotation, there may be multiple tokens with a HEAD value
        # of zero.
        head = parse(Int, columns[7])

        # col 8: DEPREL
        # Dependency relation to the HEAD. The set of dependency
        # relations depends on the particular treebank. The dependency
        # relation of a token with HEAD=0 may be meaningful or simply
        # ’ROOT’ (also depending on the treebank).
        deprel = String(columns[8])

        # col 9: PHEAD

        # Projective head of current token, which is either a value of
        # ID or zero (’0’), or an underscore if not available. The
        # dependency structure resulting from the PHEAD column is
        # guaranteed to be projective (but is not available for all
        # data sets), whereas the structure resulting from the HEAD
        # col- umn will be non-projective for some sentences of some
        # languages (but is always available).
        phead = columns[9] == "_" ? nothing : parse(Int, columns[9])

        # 10: PDEPREL
        # Dependency relation to the PHEAD, or an underscore if not
        # available.
        pdeprel = columns[10] == "_" ? nothing : String(columns[10])
        
        token = Token(
            form, head, deprel;
            id=id, lemma=lemma, cpostag=cpostag, postag=pastag,
            feats=feats, head=head, deprel=deprel, phead=phead, pdeprel=pdeprel
        )
        push!(tokens, token)
    end
    root = find_root(tokens)
    return DependencyTree(tokens, root, nothing)
end

conllx(io::IO) = conllx(readuntil(io, "\n\n"))

function to_conllx(tree::DependencyTree)
    return "TODO" 
end
