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
    @test_broken nmatches(r"<4 x double>", llvm_ir(ndrmul!, (M, M, M))) > 0
end
