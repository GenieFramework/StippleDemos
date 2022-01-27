using Stipple
using StippleUI
using StipplePlotly

using Clustering
import RDatasets: dataset
import DataFrames

data = DataFrames.insertcols!(dataset("datasets", "iris"), :Cluster => zeros(Int, 150))

@reactive mutable struct IrisModel <: ReactiveModel
  iris_data::R{DataTable} = DataTable(data)   
  credit_data_pagination::DataTablePagination =
    DataTablePagination(rows_per_page=50)     

  features::R{Vector{String}} =
    ["SepalLength", "SepalWidth", "PetalLength", "PetalWidth"]
  xfeature::R{String} = ""
  yfeature::R{String} = ""

  iris_plot_data::R{Vector{PlotData}} = []
  cluster_plot_data::R{Vector{PlotData}} = []
  layout::R{PlotLayout} = PlotLayout(plot_bgcolor = "#fff")

  no_of_clusters::R{Int} = 3
  no_of_iterations::R{Int} = 10
end

function plot_data(cluster_column::Symbol, ic_model::IrisModel)
  plot_collection = Vector{PlotData}()
  isempty(ic_model.xfeature[]) || isempty(ic_model.yfeature[]) && return plot_collection
  
  for species in Array(data[:, cluster_column]) |> unique!
    x_feature_collection, y_feature_collection = Vector{Float64}(), Vector{Float64}()
    for r in eachrow(data[data[!, cluster_column] .== species, :])
      push!(x_feature_collection, (r[Symbol(ic_model.xfeature[])]))
      push!(y_feature_collection, (r[Symbol(ic_model.yfeature[])]))
    end
    plot = PlotData(
            x = x_feature_collection,
            y = y_feature_collection,
            mode = "markers",
            name = string(species),
            plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER)
    push!(plot_collection, plot)
  end
  plot_collection
end

function compute_clusters!(ic_model::IrisModel)
  features = collect(Matrix(data[:, [Symbol(c) for c in ic_model.features[]]])')
  result = kmeans(features, ic_model.no_of_clusters[]; maxiter=ic_model.no_of_iterations[])
  data[!, :Cluster] = assignments(result)
  ic_model.iris_data[] = DataTable(data)
  ic_model.cluster_plot_data[] = plot_data(:Cluster, ic_model)

  nothing
end

function ui(model::IrisModel)
  onany(model.xfeature, model.yfeature, model.no_of_clusters, model.no_of_iterations) do (_...)
    model.iris_plot_data[] = plot_data(:Species, model)
    compute_clusters!(model)
  end

  page(
    model, class="container", title="Iris Flowers Clustering", head_content=Genie.Assets.favicon_support(),

    prepend = style(
    """
    tr:nth-child(even) {
      background: #F8F8F8 !important;
    }
    .modebar {
      display: none!important;
    }
    .st-module {
      background-color: #FFF;
      border-radius: 2px;
      box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.04);
    }
    .stipple-core .st-module > h5,
    .stipple-core .st-module > h6 {
      border-bottom: 0px !important;
    }
    """
    ),

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
          Stipple.select(:xfeature; options=:features)
        ])

        cell(class="st-module", [
          h6("Y feature")
          Stipple.select(:yfeature; options=:features)
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Species clusters")
          plot(:iris_plot_data, layout = :layout, config = "{ displayLogo:false }")
        ])

        cell(class="st-module", [
          h5("k-means clusters")
          plot(:cluster_plot_data, layout = :layout, config = "{ displayLogo:false }")
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Iris data")
          table(:iris_data; pagination=:credit_data_pagination, dense=true, flat=true, style="height: 350px;")
        ])
      ])
    ]
  )
end

route("/") do
  IrisModel |> init |> ui |> html
end

up(9000; async = true, server = Stipple.bootstrap())