module TestPlanning

include("preamble.jl")

@testset begin
    A1 = ones(0)
    A2 = ones(0, 0)
    A3 = ones(0, 0, 0)
    A4 = ones(0, 0, 0, 0)
    @test _plan(
        A1 => (:i,),
        A2 => (:i, :j),
    ).indices === _indices("ji")
    @test _plan(
        A1 => (:i,),
        A2 => (:j, :i),
        A2 => (:j, :k),
    ).indices === _indices("ikj")
    @test _plan(
        A1 => (:i,),
        A2' => (:j, :i),
        A2 => (:j, :k),
    ).indices === _indices("jki")
    @test _plan(
        A1 => (:i,),
        transpose(A2) => (:j, :i),
        A2 => (:j, :k),
    ).indices === _indices("jki")
    @test _plan(
        A1 => (:i,),
        A2' => (:j, :i),
        A2' => (:j, :k),
    ).indices === _indices("jik")
    @test _plan(
        A1 => (:i,),
        A2' => (:i, :j),
        A2' => (:k, :j),
    ).indices === _indices("ikj")
    @test _plan(
        A1 => (:i,),
        A2' => (:i, :j),
        A2 => (:i, :j),
        A3 => (:k, :i, :j),
        A4 => (:k, :j, :l, :m),
    ).indices === _indices("ijlmk")
end

end  # module
