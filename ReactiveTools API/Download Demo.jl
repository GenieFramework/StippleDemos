# Download Demo

using Stipple, Stipple.ReactiveTools
using StippleUI
using DataFrames
using XLSX

import Stipple.opts
import StippleUI.Tables.table

pushfirst!(LOAD_PATH, joinpath(ENV["USERPROFILE"], ".julia", "dev", "StippleDemos", "Plugins"))
using StippleTypedArrays
using StippleDownloads

function df_to_xlsx(df)
    io = IOBuffer()
    mktempdir() do d
        f = joinpath(d, "blend.xlsx")
        XLSX.writetable(f, "Blend" => df)
        write(io, read(f))
    end
    take!(io)
end


@app begin
    @out table = DataTable(DataFrame(:a => [1, 1, 2, 3, 2], :b => 1:5))
    @in data = TypedArray(UInt8[])
    @in data64 = TypedArray(UInt64[])
    @in text = "The quick brown fox jumped over the ..."

    @in download_df = false
    @in download_text = false

    @onbutton download_text begin
        download_text(__model__, :text)
    end

    @onbutton download_df begin
        download_binary(__model__, df_to_xlsx(table.data), "file.xlsx")
    end
end

function ui()
    row(cell(class = "st-module", [

        row([
            cell(textfield(class = "q-pr-md", "Download text", :text, placeholder = "no output yet ...", :outlined, :filled, type = "textarea"))
            cell(table(class = "q-pl-md", :table))
        ])
              
        row([
            cell(btn("Text File", icon = "download", @click(:download_text), color = "primary", nocaps = true))
            cell(btn(class = "q-ml-lg", "Excel File", icon = "download", @on(:click, :click, :addclient), color = "primary", nocaps = true))
        ])
    ]))
end

@page("/", ui)

up()


# other possible uses:

# download_binary(model, df_to_xlsx(df), "file.xlsx")
# download_binary(model, df_to_xlsx("Test" => df), "file.xlsx")
# download_binary(model, df_to_xlsx("HH" => df, "HH2" => df; anchor_cell = XLSX.CellRef("B2")), "file.xlsx")
