abstract type AxesLayout end

struct HasFast{M} <: AxesLayout
    fast::Int
    slows::NTuple{M, Int}
end

struct NoFast{N} <: AxesLayout end
struct NoAxes <: AxesLayout end

NoFast(N::Int) = NoFast{N}()

NoSlow(_N::Int) = HasFast(1, ())  # maybe create a new type?

# Base.ndims(::T) where {T <: AxesLayout} = ndims(T)
# Base.ndims(::Type{HasFast{M}}) where M = M + 1
# Base.ndims(::Type{NoFast{N}}) where N = N
# Base.ndims(::Type{NoAxes}) = 0

# fastaxis(al::HasFast) = al.fast
# fastaxis(::AxesLayout) = nothing
slowaxes(al::HasFast) = al.slows
slowaxes(::NoFast{N}) where N = ntuple(identity, N)
slowaxes(::NoAxes) = ()

slowaxes(::T) where {T} = slowaxes(AxesLayout(T))

#=
AxesLayout(::Nothing, slow::NTuple) = NoFast(slow)
AxesLayout(fast::Int, slow::NTuple) = HasFast(fast, slow)
=#

const ColumnMajor{N} = Union{
    # List taken from `strides`:
    DenseArray{<:Any, N},
    StridedReshapedArray{<:Any, N},
    StridedReinterpretArray{<:Any, N},
}

AxesLayout(::T) where T = AxesLayout(T)
AxesLayout(T::Type) = error("AxesLayout is unknown for: ", T)
AxesLayout(::Type{<:ColumnMajor{N}}) where N =
    HasFast(1, Base.tail(ntuple(identity, N)))
AxesLayout(::Type{<:Union{
    <:Adjoint{<:Any, <:ColumnMajor{1}},
    <:Adjoint{<:Any, <:ColumnMajor{2}},
    <:Transpose{<:Any, <:ColumnMajor{1}},
    <:Transpose{<:Any, <:ColumnMajor{2}},
}}) = HasFast(2, (1,))

AxesLayout(::Type{<:AbstractArray{<:Any, N}}) where N = NoFast{N}()
AxesLayout(::Type{<:Ref}) = NoAxes()

AxesLayout(::Type{BC}) where {BC <: Broadcasted} = axeslayoutargs(argstype(BC))
argstype(::Type{<:Broadcasted{<:Any, <:Any, <:Any, Args}}) where Args = Args
axeslayoutargs(::Type{Tuple{}}) = NoAxes()
axeslayoutargs(::Type{Args}) where {Args <: Tuple} =
    bcaxeslayout(AxesLayout(tuple_type_head(Args)),
                 axeslayoutargs(tuple_type_tail(Args)))

# "Computed/virtual" arrays has no slow axes.
AxesLayout(::Type{<:AbstractRange}) = NoSlow(1)  # is it?
AxesLayout(::Type{<:Union{
    CartesianIndices{N},
    LinearIndices{N},
}}) where N =
    NoSlow(N)

# Merge two `AxesLayout` in a way compatible with broadcasting
bcaxeslayout(x::NoFast, ::AxesLayout) = x
bcaxeslayout(::NoAxes, y::AxesLayout) = y
bcaxeslayout(::HasFast, y::NoFast) = y
bcaxeslayout(x::HasFast, ::NoAxes) = x
bcaxeslayout(x::HasFast{N}, y::HasFast{M}) where {N, M} =
    if x.fast !== y.fast
        NoFast{N}()
    else
        slows = foldlargs((), ntuple(identity, max(N, M))...) do slows, i
            if i === x.fast
                slows
            else
                (slows..., i)
            end
        end
        return HasFast(x.fast, slows)
    end

struct Index{x} end
const Indices{N} = NTuple{N, Index}

Index(x) = Index{x}()

indexname(::Index{x}) where x = x

struct AccessPattern{A, T <: Indices}
    indexable::A
    indices::T
end

Base.ndims(p::AccessPattern) = ndims(p.indexable)

AccessPattern(pair::Pair) = AccessPattern(pair[1], Index.(pair[2]))

struct AccessPlan{T <: Indices}
    indices::T
end

"""
    plan(args::AccessPattern...) :: AccessPlan

Try to find an index that is categorized as "fast" for all `args` with
such index.
"""
function plan(args::AccessPattern...)
    allindices = foldlargs((), args...) do indices, pattern
        tupleunion(indices, pattern.indices)
    end :: Indices
    fastindices = foldlargs(allindices, args...) do indices, pattern
        slows = map(slowaxes(pattern.indexable)) do a
            pattern.indices[a]
        end
        tuplediff(indices::Indices, slows::Indices)
    end :: Indices
    # TODO: Sort `fastindices` by the number of arrays using it?
    return AccessPlan((tuplediff(allindices, fastindices)..., fastindices...))
end
