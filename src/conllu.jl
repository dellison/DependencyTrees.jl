"""
    conllu(text)

Read an annotated sentence (`DependencyTree`) from CoNLL-U format.

# Further Reading

- [https://universaldependencies.org/format.html]
- [de Marneffe et al, 2021](https://aclanthology.org/2021.cl-2.11/) [de-marneffe-etal-2021-universal](@cite)
- [Nivre et al, 2020](https://aclanthology.org/2020.lrec-1.497/) [nivre-etal-2020-universal](@cite)
"""
function conllu(text::AbstractString)
    tokens = Token[]
    empty_tokens = Token[]
    multiword_tokens = Token[]
    metadata = Dict{String, String}()

    for line in split(text, "\n"; keepempty=false)

        # handle comments and metadata
        if startswith(line, "#")
            if occursin(" = ", line)
                key, val = string.(split(strip(line, ['#',' ']), " = "))
                metadata[key] = val
            else
                metadata[strip(line, ['#', ' '])] = true
            end
            continue
        end

        fields = split(strip(line), "\t")
        if length(fields) != 10
            error("need 10 tab-separated fields for CoNLLU, found $(length(fields)): '$line'")
        end

        # 1st column: id
        local id::Int
        try
            id = parse(Int, fields[1])
        catch
            if occursin("-", fields[1])
                i, j = (parse(Int, x) for x in split(fields[1], "-"))
                form = String(fields[2])
                push!(multiword_tokens, Token(form; i=i, j=j))
                continue
            elseif occursin(".", fields[1])
                i, j = (parse(Int, x) for x in split(fields[1], "."))
                form = String(fields[2])
                push!(empty_tokens, Token(form; i=i, j=j))
                continue
            end
        end

        # 2nd column: form
        # 3rd column: lemma
        # 4th column: upos
        # 5th column: xpos
        form, lemma, upos, xpos = String.(fields[2:5])

        # 6th column: feats
        if fields[6] == "_"
            feats = String[]
        else
            feats = String.(split(fields[6], "|"))
        end

        # 7th column: head
        if fields[7] == "_"
            head = -1
        else
            head = parse(Int, fields[7])
        end

        # 8th column: deprel
        deprel = String(fields[8])

        # 9th column: deps
        if fields[9] == "_"
            deps = Vector{Tuple{Int,String}}()
        else
            deps = Tuple{Int,String}[]
            for token in split(fields[9], "|")
                h, dr = split(token, ":")
                push!(deps, (parse(Int, h), String(dr)))
            end
        end
        
        misc = String(fields[10])

        token = Token(
            form=form, head=head, label=deprel,
            id=id, lemma=lemma, upos=upos, xpos=xpos,
            feats=feats, deprel=deprel, deps=deps, misc=misc
        )
        push!(tokens, token)
    end
    root = find_root(tokens)
    return DependencyTree(tokens, root, metadata)
end

conllu(io::IO) = conllu(readuntil(io, "\n\n"))

"""
    conllu(tree::DependencyTree)

Serialize a dependency tree to CoNLL-U format.
"""
function conllu(tree::DependencyTree)
    metadata = ["$k = $v" for (k, v) in tree.metadata]
    p = (tok, prop, nf="_", f=identity) -> begin
        isnothing(tok.data) ? nf : f(get(tok.data, p, nf))
    end
    sentence = map(enumerate(tree)) do (i, token)
        id, form, head = string(i), token.form, string(token.head)
        deprel = isnothing(token.label) ? "_" : token.label
        lemma = p(token, :lemma)
        upos, xpos = p(token, :upos), p(token, :xpos)
        feats = join(p(token, :feats, ["_"]), ",")
        deps = join(p(token, :deps, ["_"]), ",")
        misc = p(token, :misc)
        join([id, form, lemma, upos, xpos, feats, head, deprel, deps, misc], "\t")
    end
    return join(vcat(metadata, sentence), "\n")
end
