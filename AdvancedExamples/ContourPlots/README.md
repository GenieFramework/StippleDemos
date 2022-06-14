# UI Components usage using [Stipple](https://github.com/GenieFramework/Stipple.jl), [StippleUI](https://github.com/GenieFramework/StippleUI.jl), [StippleCharts](https://github.com/GenieFramework/StippleCharts.jl) and [Genie](https://github.com/GenieFramework/Genie.jl) from Stipple Ecosystem

## Run Demo

```julia
julia> julia --project
julia> #enter package mode with ]
(@v1.x) pkg> activate .
(@v1.x) pkg> instantiate
(@v1.x) pkg> #exit package mode with <backspace key>
julia> include("heatlab.jl")
# should open your default browser and fire up Genie server at port between `8000:9000`
```

![Form](assets/animation.gif)

```julia
julia> down() # stop the running async instance of Genie Server
```
