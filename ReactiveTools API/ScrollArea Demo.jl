# ScrollArea Demo

using Stipple, Stipple.ReactiveTools
using StippleUI

@appname ScrollDemo

@app begin
    @in position = 300
    @in scroll = false

    @onbutton scroll begin
        run(__model__, "this.\$refs.scrollArea.setScrollPosition($position, 500)")
        position = rand(0:1000)
    end
end

ui() = [
    heading("Scroll Area Demo" * h4("with server-side and client-side update"))
    
    row(cell(class = "st-module", [
    
        row(class = "row q-gutter-md q-mb-md", [
            btn(R"`Scroll to ${position}px`", color = "primary", @click(raw"() => this.$refs.scrollArea.setScrollPosition(position)"))
            btn(R"`Animate to ${position}px`", color = "primary", @click(:scroll))
        ])

        scrollarea(ref = "scrollArea", style = "height: 150px; max-width: 300px;",
            ol(
                li(@recur("n in 1000"), key! = "n", "Lorem ipsum dolor sit amet, consectetur adipisicing elit.")
            )
        )
    ]))
]

route("/") do 
    model = @init
    page(model, ui()) |> html
end
    
up(open_browser = true)

