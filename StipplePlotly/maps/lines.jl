using CSV, DataFrames
using Stipple, StipplePlotly 

csv_data = CSV.read(download("https://raw.githubusercontent.com/plotly/datasets/master/globe_contours.csv"), DataFrame)

scl = ["rgb(213,62,79)","rgb(244,109,67)","rgb(253,174,97)","rgb(254,224,139)","rgb(255,255,191)","rgb(230,245,152)","rgb(171,221,164)","rgb(102,194,165)","rgb(50,136,189)"];
all_lats = []
all_lons = []

for i in 1:length(scl)
    lat_head = "lat-" * string(i)
    lon_head = "lon-" * string(i)
    lat = csv_data[:, lat_head]
    lon = csv_data[:, lon_head]
    push!(all_lats, lat)
    push!(all_lons, lon)
end

data = PlotData[]

for i in 1:length(scl)
    current = PlotData(
        plot = StipplePlotly.Charts.PLOT_TYPE_SCATTERGEO,
        lon = all_lons[i],
        lat = all_lats[i],
        mode = "lines",
        line = Dict("width" => 2, "color" => scl[i])
    )

    push!(data, current)
end

@vars Model begin
    data::R{Vector{PlotData}} = data
    layout::R{PlotLayout} = PlotLayout(
        geo = PlotLayoutGeo(
            geoprojection = GeoProjection(type="orthographic", rotation=PRotation(-100,40, 0)),
            showocean = true,
            oceancolor = "rgb(0, 255, 255)",
            showland = true,
            landcolor = "rgb(230, 145, 56)",
            showlakes = true,
            lakecolor = "rgb(0, 255, 255)",
            showcountries = true,
            lonaxis = PlotLayoutAxis(xy="x", showgrid=true, gridcolor="rgb(102, 102, 102)"),
            lataxis = PlotLayoutAxis(xy="y", showgrid=true, gridcolor="rgb(102, 102, 102)")
        )
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