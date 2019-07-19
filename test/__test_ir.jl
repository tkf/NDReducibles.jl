using InteractiveUtils: code_llvm
using Test

include("../benchmark/gemm.jl")

"""
    llvm_ir(f, args) :: String

Get LLVM IR of `f(args...)` as a string.
"""
llvm_ir(f, args) = sprint(code_llvm, f, Base.typesof(args...))

nmatches(r, s) = count(_ -> true, eachmatch(r, s))

@testset "manmul!" begin
    M = ones(0, 0)
    @test nmatches(r"fmul contract <4 x double>", llvm_ir(manmul!, (M, M, M))) >= 4
end

@testset "ndrmul!" begin
    M = ones(0, 0)
    if VERSION < v"1.2-"
        CAB = _ndrmul_reducible(M, M, M)
        rf = _ndrmul_rf()
        ir = llvm_ir(transduce, (rf, nothing, CAB))
    else
        ir = llvm_ir(ndrmul!, (M, M, M))
    end
    @test nmatches(r"fmul contract <4 x double>", ir) >= 4
end
