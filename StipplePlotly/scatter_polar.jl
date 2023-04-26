using Stipple, StipplePlotly

pd(name) = PlotData(
    r = [39, 28, 8, 7, 28, 39],
    theta = ['A','B','C', 'D', 'E', 'A'],
    plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER_POLAR,
    fill = "toself",
    name = name,
)

@vars Model begin
    data::R{Vector{PlotData}} = [pd("Random 1"), pd("Random 2")]
    layout::R{PlotLayout} = PlotLayout(
        polar = PlotLayoutPolar(radialaxis= RadialAxis(true, [0, 50])),
        showlegend = false
    )
    config::R{PlotConfig} = PlotConfig()
end

function ui(model)
    page(model, class = "container", [plot(:data, layout = :layout, config = :config)])
end

route("/") do
    Stipple.init(Model) |> ui |> html
end