using CSV, DataFrames
using Stipple, StipplePlotly 

data = CSV.read(download("https://raw.githubusercontent.com/plotly/datasets/master/2010_alcohol_consumption_by_country.csv"), DataFrame)


@vars Model begin
    data::R{PlotData} = PlotData(
        plot = StipplePlotly.Charts.PLOT_TYPE_CHOROPLETH,
        locationmode = "country names",
        locations = data.location,
        z = data.alcohol,
        text = data.location,
        autocolorscale = true
    )

    layout::R{PlotLayout} = PlotLayout(
        title = PlotLayoutTitle(text="Pure alcohol consumption<br>among adults (age 15+) in 2010", font=Font(24))
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