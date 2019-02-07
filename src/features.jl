# a collection of functions that are useful for getting features from
# parser states (configurations)

const ArcXState = Union{ArcEagerState,ArcHybridState,ArcStandardState,ArcSwiftState}

# si(cfg, 0) -> top of stack
function si(cfg::ArcXState, i)
    S = length(cfg.σ)
    sid = S - i
    if 1 <= sid <= S
        aid = cfg.σ[sid]
        aid == 0 ? root(eltype(cfg.A)) : cfg.A[aid]
    else
        noval(eltype(cfg.A))
    end
end

function bi(cfg::ArcXState, i)
    B = length(cfg.β)
    if 1 <= i <= B
        cfg.A[cfg.β[i]]
    else
        noval(eltype(cfg.A))
    end
end

s(cfg::ArcXState)  = si(cfg, 0)
s0(cfg::ArcXState) = si(cfg, 0)
s1(cfg::ArcXState) = si(cfg, 1)
s2(cfg::ArcXState) = si(cfg, 2)
s3(cfg::ArcXState) = si(cfg, 3)
stack(cfg::ArcXState) = cfg.σ

b(cfg::ArcXState)  = bi(cfg, 1)
b0(cfg::ArcXState) = bi(cfg, 1)
b1(cfg::ArcXState) = bi(cfg, 2)
b2(cfg::ArcXState) = bi(cfg, 3)
b3(cfg::ArcXState) = bi(cfg, 4)
buffer(cfg::ArcXState) = cfg.σ

function leftmostdep(cfg::ParserState, i::Int, n::Int=1)
    A = arcs(cfg)
    ldep = leftmostdep(A, i, n)
    if iszero(ldep)
        root(eltype(A))
    elseif ldep == -1
        noval(eltype(A))
    else
        A[ldep]
    end
end

leftmostdep(cfg::ParserState, dep::Dependency, n::Int=1) =
    leftmostdep(cfg, id(dep), n)
    
function rightmostdep(cfg::ParserState, i::Int, n::Int=1)
    A = arcs(cfg)
    rdep = rightmostdep(A, i, n)
    if iszero(rdep)
        root(eltype(A))
    elseif rdep == -1
        noval(eltype(A))
    else
        A[rdep]
    end
end

rightmostdep(cfg::ParserState, dep::Dependency, n::Int=1) =
    rightmostdep(cfg, id(dep))
