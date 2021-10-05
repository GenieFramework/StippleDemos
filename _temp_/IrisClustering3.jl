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

#= Event handlers =#

onany(ic_model.xfeature, ic_model.yfeature, ic_model.no_of_clusters, ic_model.no_of_iterations) do (_...)
  ic_model.iris_plot_data[] = plot_data(:Species)
  compute_clusters!()
end

#= Computation =#

function plot_data(cluster_column::Symbol)
  result = Vector{PlotSeries}()
  isempty(ic_model.xfeature[]) || isempty(ic_model.yfeature[]) && return result

  dimensions = Dict()
  for s in Array(data[:, cluster_column]) |> unique!
    dimensions[s] = []

    for r in eachrow(data[data[cluster_column] .== s, :])
      push!(dimensions[s], [r[Symbol(ic_model.xfeature[])], r[Symbol(ic_model.yfeature[])]])
    end

    push!(result, PlotSeries("$s", PlotData(dimensions[s])))
  end

  result
end

function compute_clusters!()
  features = collect(Matrix(data[:, [Symbol(c) for c in ic_model.features[]]])')
  result = kmeans(features, ic_model.no_of_clusters[]; maxiter=ic_model.no_of_iterations[])
  data[:Cluster] = assignments(result)
  ic_model.iris_data[] = DataTable(data)
  ic_model.cluster_plot_data[] = plot_data(:Cluster)

  nothing
end

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