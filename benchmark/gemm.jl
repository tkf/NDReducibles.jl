using NDReducibles
using Referenceables

using Transducers
using Transducers: maybe_usesimd, BottomRF, SideEffect

function ndrmul!(C, A, B)
    simd = Val(:ivdep)

    fill!(C, 0)

    CAB = ndreducible(
        referenceable(C) => (:i, :j),
        A => (:i, :k),
        B => (:k, :j),
    )

    rf = SideEffect() do (c, a, b)
        c[] = muladd(a, b, c[])
    end
    transduce(maybe_usesimd(BottomRF{Any}(rf), simd), nothing, CAB)

    return C
end

function manmul!(C, A, B)
    fill!(C, 0)
    for j in 1:size(C, 2), k in 1:size(A, 2)
        b = @inbounds B[k, j]
        aofs = LinearIndices(A)[1, k] - 1
        cofs = LinearIndices(C)[1, j] - 1
        @simd for i in 1:size(A, 1)
            c = @inbounds C[i + cofs]
            a = @inbounds A[i + aofs]
            @inbounds C[i + cofs] = muladd(a, b, c)
        end
    end
    C
end
