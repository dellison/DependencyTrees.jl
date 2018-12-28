"""
    @feature_extractor input block

Return a feature extraction function that takes `input`
and returns features according to the code specified in `block`.
"""
macro feature_extractor(cfg, block)
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
            push!(features_expr.args, expression)
        else
            push!(assignment_exprs, expression)
        end
    end
    extractor_function_block = quote
        function (cfg)
        end
    end |> esc
    extraction_code = extractor_function_block.args[end].args[end].args[end].args
    append!(extraction_code, assignment_exprs)
    if length(features_expr.args) == 1
        push!(extraction_code, features_expr.args[1])
    else
        push!(extraction_code, features_expr)
    end
    return extractor_function_block
end

"""
    @feature_template_extractor(input, block)

Return a feature extraction function for sparse feature templates
"""
macro feature_template_extractor(input, block)
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
            featexp_args = map(expression.args) do a
                if isa(a, String)
                    a
                else
                    feat = string(a)
                    :($feat, $a)
                end
            end
            if length(featexp_args) == 1
                append!(features_expr.args, featexp_args)
            else
                feature = Expr(:tuple)
                for arg in featexp_args
                    append!(feature.args, arg.args)
                end
                push!(features_expr.args, feature)
            end
        else
            push!(assignment_exprs, expression)
        end
    end
    extractor_function_block = quote
        function (cfg)
        end
    end |> esc
    extraction_code = extractor_function_block.args[end].args[end].args[end].args
    append!(extraction_code, assignment_exprs)
    if length(features_expr.args) == 1
        push!(extraction_code, features_expr.args[1])
    else
        push!(extraction_code, features_expr)
    end
    return extractor_function_block
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

function leftmostdep(cfg::TransitionParserConfiguration, i::Int)
    A = arcs(cfg)
    ldep = leftmostdep(A, i)
    if iszero(ldep)
        root(eltype(A))
    elseif ldep == -1
        noval(eltype(A))
    else
        A[ldep]
    end
end

leftmostdep(cfg::TransitionParserConfiguration, dep::Dependency) =
    leftmostdep(cfg, id(dep))
    
function rightmostdep(cfg::TransitionParserConfiguration, i::Int)
    A = arcs(cfg)
    rdep = rightmostdep(A, i)
    if iszero(rdep)
        root(eltype(A))
    elseif rdep == -1
        noval(eltype(A))
    else
        A[rdep]
    end
end

rightmostdep(cfg::TransitionParserConfiguration, dep::Dependency) =
    rightmostdep(cfg, id(dep))
