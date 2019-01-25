"""
    @feature_template(input, block)

Return a feature extraction function for sparse feature templates.
Tuples are taken to be feature templates.
"""
macro feature_template(input, block)
    assignment_exprs = Expr[]
    features_expr = Expr(:tuple)
    featureset = Set()
    for expression in block.args
        typeof(expression) != Expr && continue
        if expression.head == :(=)
            push!(assignment_exprs, expression)
        elseif expression.head == :tuple
            if in(expression, featureset)
                println("ignoring duplicate feature template $expression")
                continue
            end
            push!(featureset, expression)
            ft_args = map(expression.args) do a
                if isa(a, String)
                    a
                else
                    feat = string(a)
                    :(string($feat, "=", isempty($a) ? "_" : $a))
                end
            end
            if length(ft_args) == 1
                append!(features_expr.args, ft_args)
            else
                feature = Expr(:call, :string)
                for (i, arg) in enumerate(ft_args)
                    append!(feature.args, [arg.args[2:end]...])
                    i < length(ft_args) && push!(feature.args, ",")
                end
                push!(features_expr.args, feature)
            end
        else
            push!(assignment_exprs, expression)
        end
    end
    args = _format_fx_input(input)
    extractor_function_block = Expr(:function, :($args), Expr(:block))
    extraction_code = extractor_function_block.args[end].args
    append!(extraction_code, assignment_exprs)
    if length(features_expr.args) == 1
        push!(extraction_code, features_expr.args[1])
    else
        push!(extraction_code, features_expr)
    end
    return extractor_function_block
end

function _format_fx_input(input)
    if isa(input, Symbol)
        input = :($input,)
    end
    if input.head != :tuple
        :($input...)
    else # ?
        input
    end
end



# si(cfg, 0) -> top of stack
function si(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}, i)
    S = length(cfg.σ)
    sid = S - i
    if 1 <= sid <= S
        aid = cfg.σ[sid]
        aid == 0 ? root(eltype(cfg.A)) : cfg.A[aid]
    else
        noval(eltype(cfg.A))
    end
end

function bi(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}, i)
    B = length(cfg.β)
    if 1 <= i <= B
        cfg.A[cfg.β[i]]
    else
        noval(eltype(cfg.A))
    end
end

# feature extraction helpers
s(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = si(cfg, 0)
s0(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = si(cfg, 0)
s1(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = si(cfg, 1)
s2(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = si(cfg, 2)
stack(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = cfg.σ
    
b(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = bi(cfg, 1)
b1(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = bi(cfg, 1)
b2(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = bi(cfg, 2)
b3(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = bi(cfg, 3)
buffer(cfg::Union{ArcEager,ArcHybrid,ArcStandard,ArcSwift}) = cfg.σ

function leftmostdep(cfg::TransitionParserConfiguration, i::Int, n::Int=1)
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

leftmostdep(cfg::TransitionParserConfiguration, dep::Dependency, n::Int=1) =
    leftmostdep(cfg, id(dep), n)
    
function rightmostdep(cfg::TransitionParserConfiguration, i::Int, n::Int=1)
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

rightmostdep(cfg::TransitionParserConfiguration, dep::Dependency, n::Int=1) =
    rightmostdep(cfg, id(dep))
