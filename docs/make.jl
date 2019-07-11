using Documenter, NDReducibles

makedocs(;
    modules=[NDReducibles],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/NDReducibles.jl/blob/{commit}{path}#L{line}",
    sitename="NDReducibles.jl",
    authors="Takafumi Arakaki <aka.tkf@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/tkf/NDReducibles.jl",
)
