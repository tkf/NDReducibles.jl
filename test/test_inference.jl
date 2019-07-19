module TestInference

include("preamble.jl")

f1() = plan(
    ND(1) => (Index(:i),),
    ND(2) => (Index(:i), Index(:j)),
)

f2() = plan(
    ND(1) => (:i,),
    ND(2) => (:i, :j),
)

@testset "plan" begin
    if VERSION < v"1.2-"
        @test_broken_inferred f1()
        @test_broken_inferred f2()
    else
        @test_inferred f1()
        @test_inferred f2()
    end
end

@testset "axisfor" begin
    patterns = AccessPattern.((
        ND(1) => (:i,),
        ND(2) => (:i, :j),
    ))
    @test_inferred _axisfor(patterns, Index(:i))
    @test_inferred _axisfor(patterns, Index(:j))
end

end  # module
