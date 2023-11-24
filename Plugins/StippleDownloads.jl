module StippleDownloads

using Stipple

export download_binary, download_text

type_dict = LittleDict(
    UInt8 => "Uint8Array",
    UInt16 => "Uint16Array",
    UInt32 => "Uint32Array",
    Int8 => "Int8Array",
    Int16 => "Int16Array",
    Int32 => "Int32Array",
    Float32 => "Float32Array",
    Float64 => "Float64Array",
    Int64 => "BigInt64Array",
    UInt64 => "BigUint64Array",
)

js_download(data, filename, mime::MIME) = """
function () {
    const blob = new Blob([$data], {type: "$mime"});
    const url = window.URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.href = url;
    link.download = '$filename';
    link.click()

    setTimeout(() => {
        window.URL.revokeObjectURL(url);
        link.remove();
    }, 100);
}
"""

function download_binary(model::ReactiveModel, js_data::JSONText, filename)
    run(model::ReactiveModel, js_download(js_data.s, filename, MIME("application/octet-stream")))
end

function download_binary(model::ReactiveModel, field::Symbol, filename, array_type = UInt8)
    big = array_type <: Union{UInt64, Int64} ? ".map(String)" : ""
    download_binary(
        model,
        JSONText("this.$field instanceof Array ? $(type_dict[array_type]).from(this.$field$big) : this.$field"),
        filename
    )
end

function download_binary(model, data, filename = "file.bin", array_type = UInt8)
    # we use a model field to send the data, in order to make use of popssibly defined revivers
    push!(model, :__download__ => data, channel = getchannel(model))
    download_binary(model, :__download__, filename, array_type)
    push!(model, :__download__ => nothing, channel = getchannel(model))
end


function download_text(model::ReactiveModel, js_data::JSONText, filename)
    run(model::ReactiveModel, js_download(js_data.s, filename, MIME("text/plain;charset=utf-8")))
end

function download_text(model::ReactiveModel, field::Symbol, filename)
    download_text(model, JSONText("this.$field"), filename)
end

function download_text(model, data, filename = "file.txt")
    # we use a model field to send the text data, in order to avoid any possible confusion with quotes
    push!(model, :__download__ => data, channel = getchannel(model))
    download_text(model, :__download__, filename)
    push!(model, :__download__ => nothing, channel = getchannel(model))
end


# --------------------------    DEMO    ----------------------------
# download_binary(model, codeunits("Hello World ϕ π 1"), "file.txt")
# download_text(model, "Hello World ϕ 3π", "file.txt")
# download_text(model, :mytext, "file.txt")
#
# function download_df_xlsx(model, df::DataFrame, filename = "file.xlsx")
#     download_binary(model, df_to_xlsx(df), filename)
# end

end