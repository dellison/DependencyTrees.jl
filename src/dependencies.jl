"""
"""
abstract type Dependency end

_ni(f, dep) = error("$f not implemented for type $(typeof(t))!")

# Dependency API:
deprel(node::Dependency) = _ni(deprel, node)
form(node::Dependency) = _ni(form, node)
head(node::Dependency) = _ni(head, node)
isroot(node::Dependency) = _ni(isroot, node)
root(t::Type{Dependency}) = _ni(root, t)

const ROOT = "ROOT"

struct UntypedDependency <: Dependency
    id::Int
    form::String
    head::Int
end
deprel(d::UntypedDependency) = nothing
form(d::UntypedDependency) = d.form
head(d::UntypedDependency) = d.head
id(d::UntypedDependency) = d.id
isroot(d::UntypedDependency) = (d.form == ROOT && d.id == 0)
root(::Type{UntypedDependency}) = UntypedDependency(0, ROOT, 0)

import Base.==
==(d1::UntypedDependency, d2::UntypedDependency) =
    d1.id == d2.id && d1.form == d2.form && d1.head == d2.head


struct TypedDependency{T} <: Dependency
    id::Int
    form::String
    data::T
    head::Int
end
deprel(d::TypedDependency) = d.data
form(d::TypedDependency) = d.form
head(d::TypedDependency) = d.head
id(d::TypedDependency) = d.id
isroot(d::TypedDependency) = (d.form == ROOT && d.id == 0)
postag(d::TypedDependency) = d.data
root(::Type{<:TypedDependency}) = TypedDependency(0, ROOT, ROOT, 0)

import Base.==
==(d1::TypedDependency, d2::TypedDependency) =
    d1.id == d2.id && d1.form == d2.form && d1.data == d2.data && d1.head == d2.head
