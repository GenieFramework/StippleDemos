# Download Demo

using Stipple, Stipple.ReactiveTools
using StippleUI
using DataFrames
using XLSX

import Stipple.opts
import StippleUI.Tables.table

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

    @event download_text begin
        # download content of an app variable
        download_text(__model__, :text)
    end

    @event download_df begin
        # download an xlsx file that is generated on the fly from an app variable
        download_binary(__model__, df_to_xlsx(table.data), "file.xlsx"; client = event["_client"])
    end
end

function ui()
    row(cell(class = "st-module", [

        row([
            cell(textfield(class = "q-pr-md", "Download text", :text, placeholder = "no output yet ...", :outlined, :filled, type = "textarea"))
            cell(table(class = "q-pl-md", :table))
        ])
              
        row([
            cell(col = 1, "Without client info")
            cell(btn("Text File", icon = "download", @on(:click, :download_text), color = "primary", nocaps = true))
            cell(col = 1, "With client info")
            cell(btn(class = "q-ml-lg", "Excel File", icon = "download", @on(:click, :download_df, :addclient), color = "primary", nocaps = true))
        ])
    ]))
end

@page("/", ui)

up(open_browser = true)