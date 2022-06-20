using Stipple, StipplePlotly 


@reactive! mutable struct Model <: ReactiveModel
    data::R{PlotData} = PlotData(
        plot = StipplePlotly.Charts.PLOT_TYPE_SCATTERMAPBOX,
        fill = "toself",
        lon = [-74, -70, -70, -74],
        lat = [47, 47, 45, 45],
       # marker = PlotDataMarker(size=10, color="orange") 
    )

    layout::R{PlotLayout} = PlotLayout(
        mapbox = PlotLayoutMapbox(style="stamen-terrain", zoom =5,  center = MCenter(-73, 46)),
        showlegend= false,
        height= 450,
        width= 600
    )

    config::R{PlotConfig} = PlotConfig()
end

model = Model |> init

function ui(model)
    page(
        model,
        class = "container",
       
        plot(:data, layout = :layout, config = :config)  
    )
end

route("/") do
    Stipple.init(Model) |> ui |> html
end