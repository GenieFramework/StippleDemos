using Genie, Genie.Renderer.Html, Stipple, StipplePlotly

t = collect(1:1:10)

pd1 = PlotData(
    x = cos.(t),
    y = sin.(t),
    z = t,
    plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER3D, # for 3D plots,
    name = "test",
)

plot_data = [pd1]

@vars Model begin
    data::R{Vector{PlotData}} = plot_data, READONLY
    layout::R{PlotLayout} = PlotLayout(
        plot_bgcolor = "#999",
        showlegend = false,
        title = PlotLayoutTitle(text = "Random numbers", font = Font(24)),
    )
    config::R{PlotConfig} = PlotConfig()
end

function ui(model)
    page(model, class = "container", [plot(:data, layout = :layout, config = :config)])
end

route("/") do
    model = Model |> init |> ui |> html
end

up()