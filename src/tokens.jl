"""
    Token(form, head=-1, label=nothing)

A token in a dependency tree.
"""
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
Token(form, head, label=nothing; kwargs...) =
    Token(form, Set(head), label, isempty(kwargs) ? nothing : Dict(kwargs))
Token(token::Token; head=token.head, label=token.label, kwargs...) =
    Token(token.form, head, label, isempty(kwargs) ? nothing : Dict(kwargs))

const Token1H{F,L} = Token{F,Int,L}
const TokenNH{F,L}  = Token{F,Set{Int},L}

const ROOT = Token("ROOT", 0, id=0)

"""
    deptoken(form, head=-1, label=nothing)

Create a token in a dependency tree.
"""
deptoken(form=nothing, head=-1, label=nothing; kwargs...) =
    Token(form, head, label; kwargs...)

function from_indices(x; form::Int=1, head=2, label=3, kw...)
    ks, is = isempty(kw) ? ((), ()) : zip(pairs(kw)...)
    new_kw = NamedTuple{ks}(Tuple(x[i] for i in is))
    return Token(x[form], x[head], x[label], new_kw...)
end

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

headisroot(t::Token1H) = t.head == 0
headisroot(t::TokenNH) = 0 in t.head
