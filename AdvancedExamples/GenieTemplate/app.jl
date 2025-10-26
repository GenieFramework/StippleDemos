if dirname(Base.active_project()) != @__DIR__
    using Pkg
    Pkg.activate(@__DIR__)
end

using GenieTemplate