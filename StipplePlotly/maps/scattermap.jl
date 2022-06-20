using Stipple, StipplePlotly


@reactive! mutable struct Model <: ReactiveModel
    data::R{PlotData} = PlotData(
                            locations= ["FRA", "DEU", "RUS", "ESP"],
                            plot = StipplePlotly.Charts.PLOT_TYPE_SCATTERGEO,
                            mode = "markers",
                            marker = PlotDataMarker(
                                size = [20, 30, 15, 10],
                                color = [10.0, 20.0, 40.0, 50.0],
                                cmin = 0.0,
                                cmax = 50.0,
                                colorscale = "Greens",
                                colorbar = ColorBar(title_text = "Some rate", ticksuffix = "%", showticksuffix = "last"),
                                line = PlotlyLine(color = "black")
                            ),
                            name = "Europe Data")


    layout::R{PlotLayout} = PlotLayout(
        plot_bgcolor = "#333",
        title = PlotLayoutTitle(text="Europe Plot", font=Font(24)),
        geo = PlotLayoutGeo(scope = "europe", resolution="50")
    )
    config::R{PlotConfig} = PlotConfig()
end

function ui(model)
    page(model, class = "container", [
        plot(:data, layout= :layout, config = :config)
    ])
end

route("/") do
    model = Model |> init |> ui |> html
end

