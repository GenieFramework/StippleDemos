# Download Demo

using Stipple, Stipple.ReactiveTools
using StippleUI

import Stipple.opts
import StippleUI.Tables.table

using StippleTypedArrays
using StippleDownloads

@deps StippleTypedArrays

@app begin
    @in data = TypedArray(UInt8[])
    @in data64 = TypedArray(UInt64[])

    @in add_data = false
    @in clear_data = false
    @in hello_world = false

    @onbutton add_data begin
        x = rand(0:255)
        push!(data, x)
        notify(data)
        push!(data64, x + 1000)
        notify(data64)
    end

    @onbutton clear_data begin
        data = data64 = []
    end
end

function ui()
    row(cell(class = "st-module q-ma-md", [
      
        row(class = "q-pa-md bg-green-2", "Data: [{{ data }}]")
        row(class = "q-pa-md q-my-lg bg-green-4", "Data64: [{{ data64 }}]")

        row([
            btn("Add data", icon = "add", @click(:add_data), color = "primary", nocaps = true)
            btn(class = "q-ml-lg", "Clear data", icon = "delete_forever", @click(:clear_data), color = "primary", nocaps = true)
        ])
    ]))
end

route("/") do
    global model
    model = @init
    page(model, ui()) |> html
end

up(open_browser = true)


# other possible uses:

# model.data[] = [1, 2, 3]
# model.data[2] += 10

# model.data64[] = [30, 20, 10]
# model.data64[2] += 10
