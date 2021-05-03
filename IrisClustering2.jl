using Stipple
using StippleUI
using StippleCharts

using Clustering
import RDatasets: dataset
import DataFrames

#= Data =#

data = DataFrames.insertcols!(dataset("datasets", "iris"), :Cluster => zeros(Int, 150))

Base.@kwdef mutable struct IrisModel <: ReactiveModel
  iris_data::R{DataTable} = DataTable(data)
  credit_data_pagination::DataTablePagination =
    DataTablePagination(rows_per_page=50)

  plot_options::PlotOptions =
    PlotOptions(chart_type=:scatter, xaxis_type=:numeric)
  iris_plot_data::R{Vector{PlotSeries}} = PlotSeries[]
  cluster_plot_data::R{Vector{PlotSeries}} = PlotSeries[]

  features::R{Vector{String}} =
    ["SepalLength", "SepalWidth", "PetalLength", "PetalWidth"]
  xfeature::R{String} = ""
  yfeature::R{String} = ""

  no_of_clusters::R{Int} = 3
  no_of_iterations::R{Int} = 10
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
          slider( 1:1:20,
                  @data(:no_of_clusters);
                  label=true)
        ])
        cell(class="st-module", [
          h6("Number of iterations")
          slider( 10:10:200,
                  @data(:no_of_iterations);
                  label=true)
        ])

        cell(class="st-module", [
          h6("X feature")
          select(:xfeature; options=:features)
        ])

        cell(class="st-module", [
          h6("Y feature")
          select(:yfeature; options=:features)
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Species clusters")
          plot(:iris_plot_data; options=:plot_options)
        ])

        cell(class="st-module", [
          h5("k-means clusters")
          plot(:cluster_plot_data; options=:plot_options)
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Iris data")
          table(:iris_data; pagination=:credit_data_pagination, dense=true, flat=true, style="height: 350px;")
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