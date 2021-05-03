using Stipple
using StippleUI
using StippleCharts

#= Data =#

Base.@kwdef mutable struct IrisModel <: ReactiveModel
end

#= Stipple setup =#

Stipple.register_components(IrisModel, StippleCharts.COMPONENTS)
const ic_model = Stipple.init(IrisModel())

#= UI =#

function ui(model::IrisModel)
  [
  dashboard(
    vm(model), class="container", title="Iris Flowers Clustering", head_content=Genie.Assets.favicon_support(),
    [
      heading("Iris data k-means clustering")

      row([
        cell(class="st-module", [
          h6("Number of clusters")
        ])
        cell(class="st-module", [
          h6("Number of iterations")
        ])

        cell(class="st-module", [
          h6("X feature")
        ])

        cell(class="st-module", [
          h6("Y feature")
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Species clusters")
        ])

        cell(class="st-module", [
          h5("k-means clusters")
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Iris data")
        ])
      ])
    ])
  ]
end

#= routing =#

route("/") do
  ui(ic_model) |> html
end

#= start server =#

up(rand((8000:9000)), open_browser=true)