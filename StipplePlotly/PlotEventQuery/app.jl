using Stipple, Stipple.ReactiveTools
using StippleUI
using StipplePlotly
using PlotlyBase

# format => [lat, lon]
cities = [
    (51.5074, -0.1278),   # London
    (40.7128, -74.0060),  # New York
    (35.6895, 139.6917),  # Tokyo
    (-33.8688, 151.2093), # Sydney
    (37.7749, -122.4194), # San Francisco
    (19.4326, -99.1332)   # Mexico City
]

# Define the two cities to connect
city1 = 1 # London
city2 = 3 # Tokyo

# Create a trace for the cities with markers
trace_cities = scattergeo(
    locationmode="ISO-3",
    lon=[city[2] for city in cities],
    lat=[city[1] for city in cities],
    mode="markers",
    marker=attr(size=10, color="blue")
)

# Create a trace for the line between the two selected cities
trace_line = scattergeo(
    locationmode="ISO-3",
    lon=[cities[city1][2], cities[city2][2]],
    lat=[cities[city1][1], cities[city2][1]],
    mode="lines",
    line=attr(width=2, color="red")
)


# Create the layout
mylayout = PlotlyBase.Layout(
    title="Connecting two cities",
    geo=attr(
        projection=attr(type="natural earth"),
        showland=true, showcountries=true,
        landcolor="#EAEAAE", countrycolor="#444444"
    )
)

# mylayout = PlotlyBase.Layout(title="Travelling Salesman Problem - Random Cities")

myconfig = PlotlyBase.PlotConfig()

# @app begin
#     @out appData = [trace_cities, trace_line]
#     @out appLayout = mylayout
#     @out appConfig = myconfig
# end

@app ARModel begin
    @out data = [trace_cities, trace_line]
    @out appLayout = mylayout
    @out appConfig = myconfig
    @mixin data::PlotlyEvents

    @onchange data_click begin
        println("plot clicked")
        @notify "hi"
        # remove point from cities
        # latitude = Float64(data_click["points"]["lat"])
        # longitude = Float64(data_click["points"]["lon"])

        @show data_click
        @info typeof(data_click)
        @info keys(data_click)

        @info data_click["points"]
        @info keys(data_click["points"])
    end

    @onchange data_hover begin
        println("plot hovered")
        @info data_hover
    end

    @onchange data_selected begin
        println("plot selected")
        @info data_selected
    end

    model
end

@mounted ARModel watchplots()

UI = Ref{Any}()

UI[] = [
    h1("GenieFramework 🧞 TSP example 🚗")
    plot(:data, layout=:appLayout, config=:appConfig, syncevents=true)
]

ui() = UI[]

route("/") do
    global model
    model = ARModel |> init |> handlers
    page(model, ui()) |> html
end

up()

