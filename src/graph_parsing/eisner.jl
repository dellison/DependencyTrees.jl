struct EisnerChart{T}
    G::DependencyGraph{T}
    table::Matrix{Tuple{T,T,T,T}}
    bp::Matrix{Tuple{Int,Int,Int,Int}}
end

function EisnerChart(G::DependencyGraph)
    t0 = typemin(eltype(G))
    table = fill((t0, t0, t0, t0), size(G))
    bp = fill((-1,-1,-1,-1), size(G))
    EisnerChart(G, table, bp)
end

abstract type PartialTree end
abstract type Triangle <: PartialTree end
abstract type Box      <: PartialTree end
struct LTriangle <: Triangle
    i::Int # root at i
    j::Int
end
struct RTriangle <: Triangle
    i::Int
    j::Int # root at j
end
struct LBox <: Box
    i::Int
    j::Int
end
struct RBox <: Box
    i::Int
    j::Int
end
Base.show(io::IO, x::LTriangle) = print(io, "$(x.i) ◺ $(x.j)")
Base.show(io::IO, x::RTriangle) = print(io, "$(x.i) ◿ $(x.j)")
Base.show(io::IO, x::LBox) = print(io, "$(x.i) △→△ $(x.j)")
Base.show(io::IO, x::RBox) = print(io, "$(x.i) △←△ $(x.j)")

_idx(t1::LTriangle) = 1
_idx(t2::RTriangle) = 2
_idx(t1::LBox)      = 3
_idx(t2::RBox)      = 4

getscore(C::EisnerChart, x::PartialTree) = C.table[x.i, x.j][_idx(x)]
getbackpointer(C::EisnerChart, x::PartialTree) = C.bp[x.i, x.j][_idx(x)]

setscore!(C::EisnerChart, s::PartialTree, x) =
    C.table[s.i,s.j] = (C.table[s.i,s.j][1:_idx(s)-1]..., x, C.table[s.i,s.j][_idx(s)+1:4]...)
setbackpointer!(C::EisnerChart, s::PartialTree, i) =
    C.bp[s.i,s.j] = (C.bp[s.i,s.j][1:_idx(s)-1]...,i,C.bp[s.i,s.j][_idx(s)+1:4]...)

arcscore(::EisnerChart{T}, ::Triangle) where T = zero(T)
arcscore(C::EisnerChart{T}, b::LBox) where T = C.G[b.i, b.j]
arcscore(C::EisnerChart{T}, b::RBox) where T = C.G[b.j, b.i]

# ATTACH-RIGHT in Eisner & Satta 1999
attachments(x::LBox, q) = (LTriangle(x.i, q), RTriangle(q+1, x.j))
attachpoints(s::LBox)   = s.i:s.j-1

# ATTACH-LEFT
attachments(x::RBox, q) = (LTriangle(x.i, q), RTriangle(q+1, x.j))
attachpoints(s::RBox)   = s.i:s.j-1

# COMPLETE-RIGHT
attachments(x::LTriangle, q) = (LBox(x.i, q), LTriangle(q, x.j))
attachpoints(s::LTriangle)   = s.i+1:s.j

# COMPLETE-LEFT
attachments(x::RTriangle, q) = (RTriangle(x.i, q), RBox(q, x.j))
attachpoints(s::RTriangle)   = s.i:s.j-1

arcset(b::LBox) = Set((Pair(b.i, b.j),))
arcset(b::RBox) = Set((Pair(b.j, b.i),))
arcset(::Triangle) = Set{Pair{Int,Int}}()

function scorer(C::EisnerChart, partial_tree::PartialTree)
    return function (q)
        l, r = attachments(partial_tree, q)
        return getscore(C, l) + getscore(C, r) + arcscore(C, partial_tree)
    end
end

function update!(C::EisnerChart, s::PartialTree)
    span = attachpoints(s)
    score, r = findmax(scorer(C, s), span)
    best_q = span[r]
    setscore!(C, s, score)
    setbackpointer!(C, s, best_q)
    return score, best_q
end

function collect_arcs(C::EisnerChart)
    n = size(C.G, 1)
    _, r = best_root(C)
    return union(
        Set((Pair(0, r),)),
        collect_arcs(C, RTriangle(1, r)),
        collect_arcs(C, LTriangle(r, n))
    )
end
function collect_arcs(C::EisnerChart, shape)
    bp = getbackpointer(C, shape)
    if bp == -1
        return Set{Pair{Int,Int}}()
    end
    left, right = attachments(shape, bp)
    return union(
        arcset(shape),
        collect_arcs(C, left),
        collect_arcs(C, right)
    )
end

function best_root(C::EisnerChart)
    n = size(C.G, 1)
    score, r = findmax(1:n) do r
        left, right = RTriangle(1, r), LTriangle(r, n)
        getscore(C, left) + getscore(C, right) + C.G[0, r]
    end
    return score, r
end

"""
    eisner(G)

Decode a projective dependency tree using the Eisner algorithm.

Use a chart parsing algorithm to decode the best possible projective tree.

# Further reading

- [Eisner & Satta, 1999](https://aclanthology.org/P99-1059/) [eisner-satta-1999-efficient](@cite)
- [Eisner, 2000](http://cs.jhu.edu/~jason/papers/#eisner-2000-iwptbook) [eisner-2000-iwptbook](@cite)
"""
function eisner(G::DependencyGraph)
    n = size(G, 1)
    C = EisnerChart(G)
    for i in 1:n
        setscore!(C, RTriangle(i, i), zero(eltype(G)))
        setscore!(C, LTriangle(i, i), zero(eltype(G)))
    end
    for j in 2:n, i in j-1:-1:1
        update!(C, LBox(i, j))
        update!(C, RBox(i, j))
        update!(C, LTriangle(i, j))
        update!(C, RTriangle(i, j))
    end
    score, r = best_root(C)
    arcs = sort(collect(union(
        Set((Pair(0,r),)),
        collect_arcs(C, RTriangle(1, r)),
        collect_arcs(C, LTriangle(r, n))
    )), by=last)
    return DependencyTree(arcs), score
end
eisner(G::AbstractMatrix) = eisner(DependencyGraph(G))
