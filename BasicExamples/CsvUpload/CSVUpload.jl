using Genie, Stipple
using Genie.Requests
using StippleUI

Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

function create_storage_dir(name)
  try
    mkdir(joinpath(@__DIR__, name)) 
    #= If you want to use Desktop dir then you may pass the following
    if Sys.iswindows()
      mkdir("$(homedir())\\Desktop\\$name")
    elseif Sys.islinux()
      mkdir("$(homedir())/$name")
    end 
    =#
  catch 
    @warn "directory already exists" 
  end
  return joinpath(@__DIR__, name)
end

# Generate file path
const FILE_PATH = create_storage_dir("Backend_Upload")
# Define react model
@reactive mutable struct APP <: ReactiveModel end

function ui(model::APP)
  page(model, title="Dashboard",
  [
      heading("Dashboard") 
      row([
        Html.div(class="col-md-12", [
          uploader(label="Upload Dataset", :auto__upload, :multiple, method="POST",
          url="http://localhost:9000/", field__name="csv_file")
        ])
      ])
  ])
end

route("/") do
  APP |> init |> ui |> html
end

#uploading csv files to the backend server
route("/", method = POST) do
  files = Genie.Requests.filespayload()
  for f in files
      write(joinpath(FILE_PATH, f[2].name), f[2].data)
      @info "Uploading: " * f[2].name
  end
  if length(files) == 0
      @info "No file uploaded"
  end
  return "upload done"
end

up(9000)
# To open the browser upon server starting please use this command
# up (PORT, , open_browser=true) # Please change the PORT to any value, i.e. 8000