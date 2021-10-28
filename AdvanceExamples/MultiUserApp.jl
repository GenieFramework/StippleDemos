# Demo case for setting up a page for multiple users
# In this example the Browser identification ('User-Agent' from the header)
# is used to distinguish users.
# If you open two instances of the app in the same browser, you will see that they synchronise,
# whereas an instance in a different browser will keep its own values.

using Stipple
using StippleCharts
using StippleUI

import Stipple.JSONParser.JSONText

Genie.Assets.assets_config!([Genie, Stipple, StippleUI, StippleCharts],
                            host = "https://cdn.statically.io/gh/GenieFramework")

# extra css for correct padding of st-br blocks ('st-pv' is not used here)
const CSS = style("""
    .st-ph {
        padding-left: 20px;
        padding-right: 20px;
    }
    .st-ph:first-child {
        padding-left: 0px;
    }
    .st-ph:last-child {
        padding-right: 0px;
    }

    .st-pv {
        padding-top: 20px;
        padding-bottom: 20px;
    }
    .st-pv:first-child {
        padding-top: 0px;
    }
    .st-pv:last-child {
        padding-bottom: 0px;
    }

    .st-bb:last-child {
        border-bottom: 0
    }
    """)

# two helper functions for defining dictionaries
OptDict = Dict{Symbol, Any}
opts(;kwargs...) = OptDict(kwargs...)

plot_options = OptDict(
    :chart => OptDict(:type => :line),
    :xaxis => OptDict(:type => :numeric),
    :yaxis => OptDict(:min => -5, :max => 5, :tickAmount => 10,
                      :labels => OptDict(:formatter => JSONText("function(val, index) { return val.toFixed(1); }"))
              )
)

# alternatively if you prefer python-style
plot_options = opts(
    chart = opts(type = :line),
    xaxis = opts(type = :numeric),
    yaxis = opts(min = -5, max = 5, tickAmount = 10,
                 labels = opts(formatter = JSONText("function(val, index) { return val.toFixed(1); }"))
            )
)

xx = Base.range(0, 4π, length=200) |> collect

Base.@kwdef mutable struct MyDashboard <: ReactiveModel
    name::R{String} = "World"
    a::R{Float64} = 1.0
    b::R{Float64} = 0.0
    c::R{Float64} = 0.0
    plot_data::R{Vector{PlotSeries}} = [PlotSeries("Sine", PlotData(zip(xx, a .* sin.(xx .- b) .+ c) |> collect))]
    plot_options::OptDict = plot_options
end

Stipple.register_components(MyDashboard, StippleCharts.COMPONENTS)
models = Dict{String, ReactiveModel}()

function ui(user)
    channel = string(hash(user))

    model = if haskey(models, channel)
        models[channel]
    else
        model = models[channel] = Stipple.init(MyDashboard(), channel = channel)

        # update plot_data when a, b or c are changed
        onany(model.a, model.b, model.c) do a, b, c
            @info "amplitude: $a, phase: $b, offset: $c"
            model.plot_data[] = [PlotSeries("Sine", PlotData(zip(xx, a .* sin.(xx .- b) .+ c) |> collect))]
        end
        model
    end

    db = dashboard(root(model), class="container", [
        heading("Demo Stipple App with multi-user and multi-client support"),

        row(cell(class="st-module", [
                h2(["Hello ", span("", @text(:name)), "!"]),
                p("I am $user")
        ])),

        row(cell(class="st-module", row([
            cell(class="st-br st-ph", [
                h5("What is your name?"),
                textfield("", :name, placeholder="type your name", label="Name", outlined="", filled="")
            ]),

            cell(class="st-br st-ph", [
                h5("Sine oder Cosine?"),
                row([
                    cell(size=4, h6("Amplitude")),
                    cell(slider( 0:0.01:5, @data(:a); markers=true, label=true, labelalways = true))
                ]),
                row([
                    cell(size=4, h6("Phase")),
                    cell(slider( 0:0.01:5, @data(:b); markers=true, label=true, labelalways = true))
                ]),
                row([
                    cell(size=4, h6("Offset")),
                    cell(slider( -3:0.01:3, @data(:c); markers=true, label=true, labelalways = true))
                ])
            ])
        ]))),
        row(cell(class="st-module", plot(:plot_data; options=:plot_options))),
        # make a nice bottom section
        footer(class="st-footer q-pa-md","Have some nicer footer here ...")
        # alternatively do
        # row("&nbsp;")
    ], title = "Stipple x-y ApexChart", channel = channel)
    return CSS * db |> html
end

route("/") do
  # deliver a user-spcific ui
  redirect("/session/$(rand(1:1_000_000))")
end

route("/session/:sid::Int") do
  params(:sid) |> ui
end

Genie.config.server_host = "127.0.0.1"

up(8500)