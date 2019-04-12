# a collection of functions that are useful for getting features from
# parser states (configurations)

const ArcX = Union{ArcEagerConfig,ArcHybridConfig,ArcStandardConfig,ArcSwiftConfig}

# si(cfg, 0) -> top of stack
function si(cfg::ArcX, i)
    S = length(cfg.σ)
    sid = S - i
    if 1 <= sid <= S
        aid = cfg.σ[sid]
        aid == 0 ? root(eltype(cfg.A)) : cfg.A[aid]
    else
        noval(eltype(cfg.A))
    end
end

function bi(cfg::ArcX, i)
    B = length(cfg.β)
    if 1 <= i <= B
        cfg.A[cfg.β[i]]
    else
        noval(eltype(cfg.A))
    end
end

s(cfg::ArcX)     = si(cfg, 0)
s0(cfg::ArcX)    = si(cfg, 0)
s1(cfg::ArcX)    = si(cfg, 1)
s2(cfg::ArcX)    = si(cfg, 2)
s3(cfg::ArcX)    = si(cfg, 3)
stack(cfg::ArcX) = cfg.σ

b(cfg::ArcX)      = bi(cfg, 1)
b0(cfg::ArcX)     = bi(cfg, 1)
b1(cfg::ArcX)     = bi(cfg, 2)
b2(cfg::ArcX)     = bi(cfg, 3)
b3(cfg::ArcX)     = bi(cfg, 4)
buffer(cfg::ArcX) = cfg.β

function σs(cfg::ArcEagerConfig)
    s = cfg.σ[end]
    σ = length(cfg.σ) > 1 ? cfg.σ[1:end-1] : Int[]
    return (σ, s)
end

function bβ(cfg::Union{ArcEagerConfig,ArcHybridConfig})
    b = cfg.β[1]
    β = length(cfg.β) > 1 ? cfg.β[2:end] : Int[]
    return (b, β)
end

leftdeps(cfg::AbstractParserConfiguration, dep::Dependency) = leftdeps(cfg, id(dep))
leftdeps(cfg::AbstractParserConfiguration, i::Int) =
    filter(t -> id(t) > i && head(t) == i, tokens(cfg))

leftmostdep(cfg::AbstractParserConfiguration, dep::Dependency, n::Int=1) =
    leftmostdep(cfg, id(dep), n)

function leftmostdep(cfg::AbstractParserConfiguration, i::Int, n::Int=1)
    A = tokens(cfg)
    ldep = leftmostdep(A, i, n)
    if iszero(ldep)
        root(eltype(A))
    elseif ldep == -1
        noval(eltype(A))
    else
        A[ldep]
    end
end

rightdeps(cfg::AbstractParserConfiguration, dep::Dependency) = rightdeps(cfg, id(dep))
rightdeps(cfg::AbstractParserConfiguration, i::Int) =
    filter(t -> id(t) > i && head(t) == i, tokens(cfg))

rightmostdep(cfg::AbstractParserConfiguration, dep::Dependency, n::Int=1) =
    rightmostdep(cfg, id(dep))

function rightmostdep(cfg::AbstractParserConfiguration, i::Int, n::Int=1)
    A = tokens(cfg)
    rdep = rightmostdep(A, i, n)
    if iszero(rdep)
        root(eltype(A))
    elseif rdep == -1
        noval(eltype(A))
    else
        A[rdep]
    end
end
