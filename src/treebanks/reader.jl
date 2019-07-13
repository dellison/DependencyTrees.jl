# read trees lazily from a single file
mutable struct TreebankReader{T<:Dependency}
    io::IO
    lineno::Int
    comment_rx::Regex
    add_id::Bool
    allow_nonprojective::Bool
    allow_multiheaded::Bool
end

TreebankReader{T}(file::String; comment_rx=r"^#", add_id=false, allow_nonprojective=true, allow_multiheaded=true) where T =
    TreebankReader{T}(open(file), 0, comment_rx, add_id, allow_nonprojective, allow_multiheaded)

Base.iterate(t::TreebankReader) = iterate(t, 1)

function Base.iterate(t::TreebankReader, state)
    T = deptype(t)
    tokens, mwts, emptytokens = T[], MultiWordToken[], EmptyToken[]
    newl, i = false, t.lineno
    while isopen(t.io) && !newl
        i += 1
        line = readline(t.io)
        occursin(t.comment_rx, line) && continue
        if isempty(line)
            !newl ? (newl = true) : break
        else
            try
                token = t.add_id ? T(length(tokens) + 1, String(line)) :
                                   T(String(line))
                push!(tokens, token)
            catch err
                isa(err, MultiWordTokenError) ? push!(mwts, MultiWordToken(line)) :
                isa(err, EmptyTokenError)     ? push!(emptytokens, EmptyToken(line)) :
                throw(err)
            end
        end
    end
    t.lineno = i
    if length(tokens) == 0
        close(t.io)
        return nothing
    else
        try
            kwargs = (check_single_head = t.allow_multiheaded ? false : true,)
            g = DependencyTree(tokens; mwts=mwts, emptytokens=emptytokens, kwargs...)
            return (g, state)
        catch err
            if isa(err, GraphConnectivityError)
                println("skipping weakly connected graph $tokens")
                return iterate(t, state)
            end
            throw(err)
        end
    end
end

deptype(::Type{<:TreebankReader{T}}) where T = T
deptype(g::TreebankReader) = deptype(typeof(g))

function Base.collect(t::TreebankReader)
    trees = DependencyTree{deptype(t)}[]
    for tree in t
        push!(trees, tree)
    end
    return trees
end
