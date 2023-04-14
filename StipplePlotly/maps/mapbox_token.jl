using Stipple
using PlotlyBase
using StipplePlotly

mapbox_token = "pk.xxxxxxxxxxx.yyyyyyyyyy"

lat = [37.7749, 40.7128, 51.5074]
lon = [-122.4194, -74.0060, -0.1278]
z = [0.5, 1, 1.5]

mydata = [
    PlotlyBase.scattermapbox(
        lat = lat,
        lon = lon,
        mode = "markers",
        marker = attr(
            size = 10,
            color = z,
            colorscale = "Viridis"
        ),
        text = ["San Francisco", "New York City", "London"],
        hoverinfo = "text"
    )
]

mylayout = PlotlyBase.Layout(

    mapbox = attr(
        accesstoken = mapbox_token,
        style = "mapbox://styles/mapbox/light-v9",
        center = attr(
            lat = 45,
            lon = 0
        ),
        pitch = 45,
        zoom = 2
    )
)

@vars ARModel begin
    mydata::R{Vector{GenericTrace}} = mydata
    mylayout::R{PlotlyBase.Layout} = mylayout
    myconfig::R{PlotlyBase.PlotConfig} = PlotlyBase.PlotConfig()
end

function ui(model::ARModel)
    page(model, class="container", [
        h1("GenieFramework 🧞 Mapbox example 📊")
        plot(:mydata, layout=:mylayout, config=:myconfig)
    ])
end

route("/") do
    ARModel |> init |> ui |> html
end

up()