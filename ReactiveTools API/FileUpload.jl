using Stipple, StippleUI, Stipple.ReactiveTools
using CSV, DataFrames

const UPLOAD = "upload"

write(joinpath(pwd(), "test.csv"), "a,b\n1,2\n10,11")

# do something with files, parse them, and put in model.df... 
@handlers begin
    @out message = ""
    @private df = DataFrame()
    @out table = DataTable()
    @onchange isready begin
        @show "App is loaded"
    end
    @onchange df table = DataTable(df)
end

@event uploaded begin
    for f in event["files"]
        f["__status"] == "uploaded" || continue
        filepath = joinpath(pwd(), UPLOAD, f["fname"])
        model.message[] *= f["fname"] * ":<br>first line: " * readline(filepath) * "<br><br><br>"
        if endswith(filepath, r"csv"i)
            model.df[] = CSV.read(filepath, DataFrame)
        end
        rm(filepath)
    end
end

@event :clear begin                                                                                                                                                 
    model.message[] = ""                                                                                                                                              
    println(event)                                                                                                                                                    
end

function ui()
    [
        uploader("Upload files", url = "/upload" , autoupload = true, :multiple,
            @on(:uploaded, :uploaded, "for (let f2 in event.files) { event.files[f2].fname = event.files[f2].name }")
        )

        card(class = "q-mt-lg q-pa-md text-white",
            style = "background: radial-gradient(circle, #35a2ff 0%, #014a88 100%); width: 30%",
            [
                cardsection(Stipple.Html.div(class = "text-h5 text-white", "Upload logs"))
                separator()
                cardsection(span(v__html = :message))
            ]
        )

        btn(class = "q-mt-lg", "Clear Log", color = "primary", @on(:click, :clear))

        table(class = "q-mt-lg", :table)
    ] |> join
end


@page("/", ui)


route("/upload", method = POST) do
    files = Genie.Requests.filespayload()
    upload_dir = joinpath(pwd(), UPLOAD)
    mkpath(upload_dir)

    for f in files
        filepath = joinpath(upload_dir, f[2].name)
        write(filepath, f[2].data)
        @info "Uploading: " * f[2].name
        # if no model context is necessary, the data can be loaded here
        if endswith(filepath, r"csv"i)
            df = CSV.read(filepath, DataFrame)
            @info df
        end
    end

    if length(files) == 0
        @info "No file uploaded"
    end

end


up()