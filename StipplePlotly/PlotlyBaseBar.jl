using Stipple
using PlotlyBase
using StipplePlotly

trace1 = PlotlyBase.bar(;x=["giraffes", "orangutans", "monkeys"],
                  y=[20, 14, 23],
                  name="SF Zoo",
                  marker=attr(color="gray"))

trace2 = PlotlyBase.bar(x=["giraffes", "orangutans", "monkeys"],
                 y=[12, 18, 29],
                 name="LA Zoo")

@reactive! mutable struct BarPlot <: ReactiveModel
    data::R{Vector{GenericTrace}} = [trace1, trace2]

    my_layout::R{PlotlyBase.Layout} = PlotlyBase.Layout(;barmode="stack")

    my_config::R{PlotlyBase.PlotConfig} = PlotlyBase.PlotConfig()
end

function ui(model::Example)
    page(model, class="container", [
        plot(:data, layout=:my_layout, config=:my_config)
    ])
end

route("/") do
    BarPlot |> init |> ui |> html
end

up(8800)
