module TestNdreducible
using Test

@info "Running test_inference.jl for the first time."
try
    include("test_inference.jl")
catch
    @info "Got an error as expected..."
end

@info "Running test_inference.jl for the second time. This should work..."
include("test_inference.jl")

@testset "$file" for file in sort([file for file in readdir(@__DIR__) if
                                   match(r"^test_.*\.jl$", file) !== nothing])
    include(file)
end

end
