abstract type Dependency end

_ni(f, dep) = error("$f not implemented for type $(typeof(dep))!")

# Dependency API:
dep(node::Dependency, args...; head=0, kwargs...) = _ni(dep, node)
deprel(node::Dependency) = _ni(deprel, node)
form(node::Dependency) = _ni(form, node)
hashead(node::Dependency) = _ni(hashead, node)
head(node::Dependency) = _ni(head, node)
isroot(node::Dependency) = _ni(isroot, node)
noval(node::Dependency) = _ni(noval, node)
root(t::Type{<:Dependency}) = _ni(root, t)
unk(t::Type{<:Dependency}) = _ni(unk, t)

const ROOT = "ROOT"
const NOVAL = "NOVAL"

leftdeps(tokens::AbstractVector, i::Int) =
    id.(filter(t -> id(t) < i && head(t) == i, tokens))

leftdeps(tokens::AbstractVector, dep::Dependency) =
    filter(t -> id(t) < id(dep) && head(t) == id(dep), tokens)

rightdeps(tokens::AbstractVector, i::Int) =
    id.(filter(t -> id(t) > i && head(t) == i, tokens))

rightdeps(tokens::AbstractVector, dep::Dependency) =
    filter(t -> id(t) > id(dep) && head(t) == id(dep), tokens)

function leftmostdep(tokens::AbstractVector, i::Int, n::Int=1, notfound::Int=-1)
    deps = filter(a -> i > id(a) && hashead(a) && head(a) == i, tokens)
    return length(deps) < n ? notfound : id(deps[n])
end
function leftmostdep(tokens::AbstractVector, dep::Dependency, n::Int=1)
    ldep = leftmostdep(tokens, id(dep), n)
    return ldep == -1 ? noval(eltype(tokens)) : tokens[ldep]
end

function rightmostdep(tokens::AbstractVector, i::Int, n::Int=1, notfound::Int=-1)
    deps = filter(a -> i < id(a) && hashead(a) && head(a) == i, tokens)
    return length(deps) < n ? notfound : id(deps[end-n+1])
end
function rightmostdep(tokens::AbstractVector, dep::Dependency, n::Int=1)
    rdep = rightmostdep(tokens, id(dep), n)
    return rdep == -1 ? noval(eltype(tokens)) : tokens[rdep]
end


struct MultiWordToken
    i::Int
    j::Int
    word::String
end

function MultiWordToken(line::String)
    fields = split(line, "\t")
    i, j = match(r"([0-9]+)-([0-9]+)", fields[1]).captures
    MultiWordToken(parse(Int, i), parse(Int, j), String(fields[2]))
end

struct EmptyToken
    id::Float32
    word::String
end

function EmptyToken(line::String)
    fields = split(line, "\t")
    EmptyToken(parse(Float32, fields[1]), String(fields[2]))
end

"""
    UntypedDependency(id, form, head)

Represents a simple untyped (head --> dependent) relation between two
words in a sentence.
"""
struct UntypedDependency <: Dependency
    id::Int
    form::String
    head::Int
end

function UntypedDependency(line::String)
    xs = split(strip(line))
    UntypedDependency(parse(Int, xs[1]), String(xs[2]), parse(Int, xs[3]))
end

function UntypedDependency(id::Int, line::String)
    form, head = split(strip(line))
    UntypedDependency(id, String(form), parse(Int, head))
end

dep(d::UntypedDependency, _args...; head=head(d)) =
    UntypedDependency(d.id, d.form, head)

typed(d::UntypedDependency) = ()

id(d::UntypedDependency) = d.id
deprel(d::UntypedDependency) = ()
form(d::UntypedDependency) = d.form
hashead(d::UntypedDependency) = (d.head >= 0)
head(d::UntypedDependency) = d.head

isroot(d::UntypedDependency) = (d.form == ROOT && d.id == 0)
noval(::Type{UntypedDependency}) = UntypedDependency(-1, NOVAL, -1)
root(::Type{UntypedDependency}) = UntypedDependency(0, ROOT, 0)

toconllu(d::UntypedDependency) =
    join([d.id,d.form,"_","_","_","_",d.head,"_","_","_"],"\t")*"\n"

unk(::Type{UntypedDependency}, id, word) = UntypedDependency(id, word, -1)

==(d1::UntypedDependency, d2::UntypedDependency) =
    d1.id == d2.id && d1.form == d2.form && d1.head == d2.head

"""
    TypedDependency(id, form, deprel, head)

Represents a typed (head -[deprel]-> dependent) relation between two
words in a sentence. `id` is the index of the word `form` in the
sentence (starting at 1, with 0 meaning the root node). `deprel` is
the dependency relation between this word and its `head`).
"""
struct TypedDependency{T} <: Dependency
    id::Int
    form::String
    deprel::T
    head::Int
end

function TypedDependency(line::AbstractString; read_deprel=String)
    xs = String.(split(strip(line)))
    id = parse(Int, xs[1])
    form = xs[2]
    deprel = read_deprel(xs[3])
    head = parse(Int, xs[4])
    TypedDependency(id, form, deprel, head)
end

function TypedDependency(id::Int, line::AbstractString; read_deprel=String)
    xs = String.(split(strip(line)))
    form = xs[1]
    deprel = read_deprel(xs[2])
    head = parse(Int, xs[3])
    TypedDependency(id, form, deprel, head)
end

dep(d::TypedDependency, deprel=deprel(d); head=head(d)) =
    TypedDependency(d.id, d.form, deprel, head)

id(d::TypedDependency) = d.id
deprel(d::TypedDependency) = d.deprel
form(d::TypedDependency) = d.form
hashead(d::TypedDependency) = (d.head >= 0)
head(d::TypedDependency) = d.head
isroot(d::TypedDependency) = (d.form == ROOT && d.id == 0)
root(::Type{<:TypedDependency}) = TypedDependency(0, ROOT, ROOT, 0)
noval(::Type{<:TypedDependency}) = TypedDependency(-1, NOVAL, NOVAL, -1)

toconllu(d::TypedDependency) =
    join([d.id,d.form,"_","_","_","_",d.head,d.deprel,"_","_"],"\t")*"\n"

unk(::Type{TypedDependency}, id, word) = TypedDependency(id, word, undef, -1)

==(d1::TypedDependency, d2::TypedDependency) =
    all([d1.id == d2.id, d1.form == d2.form,
         d1.deprel == d2.deprel, d1.head == d2.head])
