module BenchGEMM

using BenchmarkTools

include("gemm.jl")

let
    A = randn(3, 3)
    B = randn(3, 3)
    desired = A * B
    C = zero(desired)

    @assert ndrmul!(C, A, B) ≈ desired
    @assert manmul!(C, A, B) ≈ desired
end

suite = BenchmarkGroup()

let sub = suite["mul"] = BenchmarkGroup()
    for impl in ["ndr", "man"]
        sub[impl] = BenchmarkGroup()
    end
end

# for n in [8, 32, 256]
for n in [32]
    A = randn(n, n)
    B = randn(n, n)
    desired = A * B
    C = zero(desired)

    sub = suite["mul"]
    for (impl, f) in [("ndr", ndrmul!), ("man", manmul!)]
        sub[impl][n] = @benchmarkable($f($C, $A, $B))
    end
end

end  # module
BenchGEMM.suite
