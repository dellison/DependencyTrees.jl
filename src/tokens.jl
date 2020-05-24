
# TODO should tokens always know their IDs?
# TODO default label (deprel)?
struct Token{F,H<:Union{Int,Set{Int}},L}
    form::F
    head::H
    label::L
    data # Union{Nothing,Dict} ?
end

Token() = Token(nothing, -1, nothing, nothing)
function Token(form, head::Int=-1, label=nothing; kwargs...)
    return Token(form, head, label, isempty(kwargs) ? nothing : Dict(kwargs))
end
function Token(form, head, label=nothing; kwargs...)
    return Token(form, Set(head), label; kwargs...)
end
Token(token::Token; head=token.head, label=token.label, kwargs...) =
    Token(token.form, head, label, isempty(kwargs) ? nothing : Dict(kwargs))

const Token1H{F,L} = Token{F,Int,L}
const TokenNH{F,L}  = Token{F,Set{Int},L}

const ROOT = Token("ROOT", 0, id=0)

"""
    deptoken(form, [head], [label]; kw...)
    
Create a `DependencyTrees.token`.
"""
deptoken(a...; k...) = Token(a...; k...)

function from_indices(x; form::Int=1, head=2, label=3, kw...)
    ks, is = isempty(kw) ? ((), ()) : zip(pairs(kw)...)
    new_kw = NamedTuple{ks}(Tuple(x[i] for i in is))
    return Token(x[form], x[head], x[label], new_kw...)
end

# TODO token api?

isroot(t::Token) = t === ROOT

has_head(token::Token1H) = token.head >= 0
has_head(token::TokenNH) = !isempty(token.head)
    
has_head(token::Token1H, h::Int) = token.head == h
has_head(token::TokenNH, h::Int) = h in token.head

function Base.getproperty(t::Token, f::Symbol)
    try
        getfield(t, f)
    catch
        try
            t.data[f]
        catch
            error("$t has no field $f")
        end
    end
end

==(a::Token, b::Token) =
    a.form == b.form && a.head == b.head && a.label == b.label && a.data == b.data

# dep(t::Token, a...; k...) = 
# deprel
# form
# hashead
# isroot
# noval

headisroot(t::Token1H) = t.head == 0
headisroot(t::TokenNH) = 0 in t.head
