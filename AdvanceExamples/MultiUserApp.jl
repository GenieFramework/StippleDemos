# Demo case for setting up a page for multiple users
# In this example the Browser identification ('User-Agent' from the header)
# is used to distinguish users.
# If you open two instances of the app in the same browser, you will see that they synchronise,
# whereas an instance in a different browser will keep its own values.

using Stipple
using StippleCharts
using StippleUI

# Genie.Assets.assets_config!([Genie, Stipple, StippleUI, StippleCharts],
#                             host = "https://cdn.statically.io/gh/GenieFramework")

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

# helper function for defining dictionaries
const OptDict = Dict{Symbol, Any}
const plot_options = OptDict(
    :chart => OptDict(:type => :line),
    :xaxis => OptDict(:type => :numeric),
    :yaxis => OptDict(:min => -5, :max => 5, :tickAmount => 10,
                        :labels => OptDict(:formatter => JSONText("function(val, index) { return val.toFixed(1); }"))
                )
)

# alternatively if you prefer python-style
# opts(;kwargs...) = OptDict(kwargs...)
# const plot_options = opts(
#     chart = opts(type = :line),
#     xaxis = opts(type = :numeric),
#     yaxis = opts(min = -5, max = 5, tickAmount = 10,
#                     labels = opts(formatter = JSONText("function(val, index) { return val.toFixed(1); }"))
#             )
# )

const xx = Base.range(0, 4π, length=200) |> collect

@reactive mutable struct MyDashboard <: ReactiveModel
    a::R{Float64} = 1.0
    b::R{Float64} = 0.0
    c::R{Float64} = 0.0
    plot_data::R{Vector{PlotSeries}} = [PlotSeries("Sine", PlotData(zip(xx, a .* sin.(xx .- b) .+ c) |> collect))]
    plot_options::R{OptDict} = plot_options, JSFUNCTION
end

Stipple.register_components(MyDashboard, StippleCharts.COMPONENTS)

models = Dict{String, ReactiveModel}()

function model(channel)
    if haskey(models, channel)
        models[channel]
    else
        model = models[channel] = init(MyDashboard, channel = channel)

        # update plot_data when a, b or c are changed
        onany(model.a, model.b, model.c) do a, b, c
            @info "amplitude: $a, phase: $b, offset: $c"
            model.plot_data[] = [PlotSeries("Sine", PlotData(zip(xx, a .* sin.(xx .- b) .+ c) |> collect))]
        end

        on(model.isready) do _
            push!(model)
        end

        model
    end
end

function ui(user_id)
        CSS *
        page(model(user_id), class="container", [

        heading("Demo Stipple App with multi-user and multi-client support (user $user_id)")

        row([
            cell(class="st-br st-ph", [
                h5("Sine oder Cosine?")

                row([
                    cell(size=4, h6("Amplitude"))
                    cell(slider( 0:0.01:5, @data(:a); markers=true, label=true, labelalways = true))
                ])

                row([
                    cell(size=4, h6("Phase"))
                    cell(slider( 0:0.01:5, @data(:b); markers=true, label=true, labelalways = true))
                ])

                row([
                    cell(size=4, h6("Offset"))
                    cell(slider( -3:0.01:3, @data(:c); markers=true, label=true, labelalways = true))
                ])
            ])
        ])

        row(cell(class="st-module", plot(:plot_data; options=:plot_options)))

        row([
            footer([
                h6("Powered by Stipple")
            ])
        ])
    ], title = "Stipple x-y ApexChart", @iif(:isready))
end

route("/") do
    # deliver a user-spcific ui
    redirect("/session/$(rand(1:1_000_000))")
end

route("/session/:sid") do
    params(:sid) |> ui |> html
end

up(8500)