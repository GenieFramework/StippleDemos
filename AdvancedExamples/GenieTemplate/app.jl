using Pkg

cd(@__DIR__)
dirname(Base.active_project()) != pwd() && Pkg.activate(@__DIR__)

using GenieTemplate

@wait