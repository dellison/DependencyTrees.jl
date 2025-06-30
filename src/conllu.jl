"""
    from_conllu(cfg, line)

Read a token (in a dependency tree) from CoNLL-U format.
"""
function from_conllu(line::AbstractString)
    local id::Int
    metadata = Dict{String, String}()
    if startswith(line, "#")
        key, val = string.(split(strip(line, ['#',' ']), " = "))
        throw(MetadataError(key, val))
    end
    fields = split(strip(line), "\t")
    if length(fields) != 10
        error("need 10 tab-separated fields for CoNLLU, found $(length(fields)): '$line'")
    end
    try
        id = parse(Int, fields[1])
    catch
        if occursin("-", fields[1])
            # i, j = Int.(split(fields[1], "-"))
            i, j = (parse(Int, x) for x in split(fields[1], "-"))
            form = String(fields[2])
            throw(MultiWordTokenError(deptoken(form; i=i, j=j)))
        elseif occursin(".", fields[1])
            i, j = (parse(Int, x) for x in split(fields[1], "."))
            form = String(fields[2])
            throw(EmptyTokenError(deptoken(form; i=i, j=j)))
        end
    end
    form, lemma, upos, xpos = String.(fields[2:5])
    if fields[6] == "_"
        feats = String[]
    else
        feats = String.(split(fields[6], "|"))
    end

    # head is in the seventh column.
    if fields[7] == "_"
        head = -1
    else
        head = parse(Int, fields[7])
    end
    deprel = String(fields[8])
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
    return deptoken(form, head, deprel;
                 id=id, lemma=lemma, upos=upos, xpos=xpos,
                 feats=feats, deprel=deprel, deps=deps, misc=misc)
end

to_conllu(tree::DependencyTree) =
    join([toconllu(i, tk) for (i, tk) in enumerate(tree)], "\n")

function _prop(t::Token, p::Symbol, nf="_", f=identity)
    t.data === nothing && return nf
    f(get(t.data, p, nf))
end

function toconllu(id::Int, t::Token)
    id, form, head = string(id), t.form, string(t.head)
    deprel = t.label == nothing ? "_" : t.label
    lemma = _prop(t, :lemma)
    upos, xpos = _prop(t, :upos), _prop(t, :xpos)
    feats = join(_prop(t, :feats, ["_"]), ",")
    deps = join(_prop(t, :deps, ["_"]), ",")
    misc = _prop(t, :misc)
    join([id, form, lemma, upos, xpos, feats, head, deprel, deps, misc], "\t")
end

