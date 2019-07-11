"""
    CoNLLU

CoNLLU token in a dependency tree.

See [https://universaldependencies.org/format.html](https://universaldependencies.org/format.html).
"""
struct CoNLLU <: Dependency
    "id: Word index, integer starting at 1 for each new sentence; may be a range for multiword tokens; may be a decimal number for empty nodes."
    id::Int
    "form: Word form or punctuation symbol."
    form::String
    "lemma: Lemma or stem of word form."
    lemma::String
    "upos: Universal part-of-speech tag."
    upos::String
    "xpos: Language-specific part-of-speech tag; underscore if not available."
    xpos::String
    "feats: List of morphological features from the universal feature inventory or from a defined language-specific extension; underscore if not available."
    feats::Vector{String}
    "head: Head of the current word, which is either a value of ID or zero (0)."
    head::Int
    "deprel: Universal dependency relation to the HEAD (root iff HEAD = 0) or a defined language-specific subtype of one."
    deprel::String
    "deps: Enhanced dependency graph in the form of a list of head-deprel pairs."
    deps::Vector{Tuple{Int,String}}
    "misc: Any other annotation."
    misc::String
end

function CoNLLU(line::AbstractString; add_id=false)
    local id
    fields = split(strip(line), "\t")
    if length(fields) != 10
        error("need 10 tab-separated fields for CoNLLU, found $(length(fields)): '$line'")
    end
    try
        id = parse(Int, fields[1])
    catch
        occursin("-", fields[1]) && throw(MultiWordTokenError())
        occursin(".", fields[1]) && throw(EmptyTokenError())
    end
    form = String(fields[2])
    lemma = String(fields[3])
    upos = String(fields[4])
    xpos = String(fields[5])
    if fields[6] == "_"
        feats = String[]
    else
        feats = String.(split(fields[6], "|"))
    end
    head = parse(Int, fields[7])
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
    CoNLLU(id, form, lemma, upos, xpos, feats, head, deprel, deps, misc)
end

id(d::CoNLLU) = d.id
form(d::CoNLLU) = d.form
lemma(d::CoNLLU) = d.lemma
upos(d::CoNLLU) = d.upos
xpos(d::CoNLLU) = d.xpos
feats(d::CoNLLU) = d.feats
head(d::CoNLLU) = d.head
deprel(d::CoNLLU) = d.deprel
deps(d::CoNLLU) = d.deps
misc(d::CoNLLU) = d.misc

dep(d::CoNLLU, deprel; lemma=lemma(d), upos=upos(d), xpos=xpos(d), feats=feats(d),
    head=head(d), deps=deps(d), misc=misc(d)) =
        CoNLLU(d.id, d.form, lemma, upos, xpos, feats, head, deprel, deps, misc)

dep(d::CoNLLU; lemma=lemma(d), upos=upos(d), xpos=xpos(d), feats=feats(d),
    head=head(d), deprel=deprel(d), deps=deps(d), misc=misc(d)) =
        CoNLLU(d.id, d.form, lemma, upos, xpos, feats, head, deprel, deps, misc)


hashead(d::CoNLLU) = d.head >= 0

noval(::Type{CoNLLU}) = CoNLLU(-1,NOVAL,NOVAL,NOVAL,NOVAL,String[],-1,NOVAL,Tuple{Int,String}[],NOVAL)
root(::Type{CoNLLU}) = CoNLLU(0,ROOT,ROOT,ROOT,ROOT,String[],0,ROOT,Tuple{Int,String}[],ROOT)
isroot(d::CoNLLU) = d.id == 0 && d.form == ROOT

unk(::Type{CoNLLU},id,word::String,lemma="_",upos="_",xpos="_",feats=String[]) =
    CoNLLU(id,word,lemma,upos,xpos,feats,-1,"",Tuple{Int,String}[],"")

function toconllu(d::CoNLLU)
    id, head = string(d.id), string(d.head)
    form, lemma, upos, xpos, deprel, misc = d.form, d.lemma, d.upos, d.xpos, d.deprel, d.misc
    feats = join(d.feats, "|")
    deps = join([join((h,d), ":") for (h,d) in d.deps], "|")
    isempty(feats) && (feats = "_")
    isempty(deps) && (deps = "_")
    join([id, form, lemma, upos, xpos, feats, head, deprel, deps, misc], "\t")*"\n"
end

Base.show(io::IO, d::CoNLLU) = print(io, toconllu(d))

==(d1::CoNLLU, d2::CoNLLU) =
    all([d1.id == d2.id, d1.form == d2.form, d1.lemma == d2.lemma,
          d1.upos == d2.upos, d1.xpos == d2.xpos, d1.feats == d2.feats,
          d1.head == d2.head, d1.deprel == d2.deprel, d1.deps == d2.deps,
          d1.misc == d2.misc])
