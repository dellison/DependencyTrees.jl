"""
    Dependency

Abstract type defining a dependency relation between
two words in a sentence.
"""
abstract type Dependency end

_ni(f, dep) = error("$f not implemented for type $(typeof(dep))!")

# Dependency API:
dep(node::Dependency, args...; head=0, kwargs...) = _ni(dep, node)
depargs(node::Dependency) = _ni(depargs, node)
deprel(node::Dependency) = _ni(deprel, node)
form(node::Dependency) = _ni(form, node)
head(node::Dependency) = _ni(head, node)
isroot(node::Dependency) = _ni(isroot, node)
root(t::Type{Dependency}) = _ni(root, t)
unk(t::Type{Dependency}) = _ni(unk, t)

const ROOT = "ROOT"

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

dep(d::UntypedDependency, _args...; head=head(d)) =
    UntypedDependency(d.id, d.form, head)
depargs(::Type{UntypedDependency}) = x::UntypedDependency -> ()

id(d::UntypedDependency) = d.id
deprel(d::UntypedDependency) = nothing
form(d::UntypedDependency) = d.form
head(d::UntypedDependency) = d.head

isroot(d::UntypedDependency) = (d.form == ROOT && d.id == 0)
root(::Type{UntypedDependency}) = UntypedDependency(0, ROOT, 0)

isunk(d::UntypedDependency) = d.head == -1
unk(::Type{UntypedDependency}, id, word) = UntypedDependency(id, word, -1)

import Base.==
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

dep(d::TypedDependency, deprel; head=head(d)) = TypedDependency(d.id, d.form, deprel, head)
depargs(::Type{<:TypedDependency}) = x::TypedDependency -> (deprel(x),)

id(d::TypedDependency) = d.id
deprel(d::TypedDependency) = d.deprel
form(d::TypedDependency) = d.form
head(d::TypedDependency) = d.head
isroot(d::TypedDependency) = (d.form == ROOT && d.id == 0)
root(::Type{<:TypedDependency}) = TypedDependency(0, ROOT, ROOT, 0)
unk(::Type{TypedDependency}, id, word) = TypedDependency(id, word, undef, -1)

import Base.==
==(d1::TypedDependency, d2::TypedDependency) =
    all([d1.id == d2.id, d1.form == d2.form,
         d1.deprel == d2.deprel, d1.head == d2.head])
