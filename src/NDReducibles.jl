module NDReducibles

export ndreducible

using Base:
    StridedReinterpretArray,
    StridedReshapedArray,
    tuple_type_head,
    tuple_type_tail
using Base.Broadcast: Broadcasted

using LinearAlgebra: Adjoint, Transpose
using Transducers:
    @next,
    @return_if_reduced,
    @simd_if,
    Foldable,
    Transducers,
    complete,
    foldlargs,
    ifunreduced,
    reduced,
    unreduced

include("base.jl")
include("planning.jl")
include("reduce.jl")
include("show.jl")

end # module
