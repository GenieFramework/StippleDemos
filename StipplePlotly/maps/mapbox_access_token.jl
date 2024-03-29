using Stipple, StipplePlotly 


@reactive! mutable struct Model <: ReactiveModel
    data::R{PlotData} = PlotData(
        plot = StipplePlotly.Charts.PLOT_TYPE_CHOROPLETHMAPBOX,
       	name = "US States",
       	geojson = "https://raw.githubusercontent.com/python-visualization/folium/master/examples/data/us-states.json",
        locations= [ "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY" ],
        z = [ 141, 140, 155, 147, 132, 146, 151, 137, 146, 136, 145, 141, 149, 151, 138, 158, 164, 141, 146, 145, 142, 150, 155, 160, 156, 161, 147, 164, 150, 152, 155, 167, 145, 146, 151, 154, 161, 145, 155, 150, 151, 162, 172, 169, 170, 151, 152, 173, 160, 176 ],
        zmin = 25, 
        zmax = 280,
        colorbar =Dict("y" => 0, "yanchor" => "bottom", "title" => Dict("text" => "US states", "side" => "right"))

    )

    layout::R{PlotLayout} = PlotLayout(
        mapbox = PlotLayoutMapbox(style="dark", zoom =0,  center = MCenter(-110, 50)),
        height= 400,
        width= 600,
        margin_t = 0,
        margin_b = 0
    )

    config::R{PlotConfig} = PlotConfig(
        mapbox_access_token = "your mapbox access token")
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