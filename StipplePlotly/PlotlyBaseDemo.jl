using Stipple, StipplePlotly
using PlotlyBase

@reactive! mutable struct Example <: ReactiveModel
    plot::R{Plot} = Plot()
end

function ui(model::Example)
    page(model, class = "container", [
        plot("plot.data", layout = "plot.layout", config = "plot.config")
    ])
end

model = init(Example, debounce=0)
route("/") do
    model |> ui |> html
end

up(8800)

for i in 1:30
    model.plot[] = Plot(rand(100,2))
    sleep(0.1)
end