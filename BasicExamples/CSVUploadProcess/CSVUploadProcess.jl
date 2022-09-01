using Genie, Stipple
using Genie.Requests
using StippleUI
using StipplePlotly
using Clustering
using DataFrames
using CSV

Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

data = DataFrame()

function create_storage_dir(name)
    isdir(name) ? rm(name, recursive=true) : println("No $name dir exists. Creating ...")
    
    try
        mkdir(joinpath(@__DIR__, name))
    catch
        @warn "directory already exists"
    end

    return joinpath(@__DIR__, name)
end

#DataFrames.insertcols!(DataFrame(CSV.File("Backend_Upload/iris.csv")), :Cluster => zeros(Int, 150))

# Generate file path
const FILE_PATH = create_storage_dir("Backend_Upload")

# Define reactive model
@reactive mutable struct IrisModel <: ReactiveModel
    iris_data::R{DataTable} = DataTable(data)   
    credit_data_pagination::DataTablePagination =
      DataTablePagination(rows_per_page=50)     
  
    features::R{Vector{String}} =
      ["sepal_length", "sepal_width", "petal_length", "petal_width"]
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

function handlers(model::IrisModel)
    onany(model.xfeature, model.yfeature, model.no_of_clusters, model.no_of_iterations) do (_...)
        model.iris_plot_data[] = plot_data(:species, model)
        compute_clusters!(model)
    end

    model
end

function ui(model::IrisModel)
    
    page(model, title="Upload Dashboard",
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
        heading("Dashboard") 
        row([
            Html.div(class="col-md-12", [
                uploader(label="Upload Dataset", :auto__upload, :multiple, method="POST",
                url="http://localhost:9000/", field__name="csv_file")
            ])
        ])

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
    ])
end

iris_model = init(IrisModel)

route("/") do
    iris_model |> handlers |> ui |> html
end

#uploading csv files to the backend serverf
route("/", method = POST) do
    files = Genie.Requests.filespayload()
    for f in files
        write(joinpath(FILE_PATH, f[2].name), f[2].data)
        @info "Uploading: " * f[2].name
    end
    if length(files) == 0
        @info "No file uploaded"
    end

  global data = DataFrames.insertcols!(DataFrame(CSV.File("Backend_Upload/iris.csv")), :Cluster => zeros(Int, 150))
  iris_model.iris_data[] = DataTable(data)
  return "upload done"
end

up(9000)