module SlideShows

using Stipple, Stipple.ReactiveTools
using StippleUI

Stipple.enable_model_storage(false)

@app Slideshow begin
    @in title = "Hurghada & Luxor - 2024"
    @in imagedir = "images"
    @in images = String[]
    @in empties = 30
    @in selection = fill(0, 18)
    @in change = false
    @in fitmode = "contain"
    @out duration = 4.0
    @out interval = 1.5
    @private last_images = Int[]
    @private last_selections = Int[]

    @in raster = [3, 6]

    @onchange isready begin
        images = "/images/" .* readdir("public/$imagedir")
        run(model, "this.updateRaster(); this.slideshow = setInterval(() => this.change = true, $(1000 * interval))")
    end

    @onchange raster begin
        n_old = length(selection)
        n = prod(raster)
        n < n_old && (selection[!][n + 1:end] .= 0)
        push!(selection)
        resize!(selection, n)
        selection[!][n_old + 1:end] .= 0
        interval = n < 12 ? 5 - 3.5 * (n - 1) / 12 : 1.5
        run(model, "clearInterval(this.slideshow); this.slideshow = setInterval(() => this.change = true, $(1000 * interval))")
    end

    @onbutton change begin
        # no empty pictures for less than 4 pictures
        lowerindex = if prod(raster) < 4
            1
        else
            lowerindex = 1 - round(Int, length(images) *  empties / 100) # lower index than 1 will not find an image and stay empty
        end

        available = setdiff(lowerindex:length(images), selection, last_images)
        i = if isempty(available)
            rand(lowerindex:length(images))
        else
            i = rand(1:length(available))
        end

        available_selections = setdiff(1:length(selection), last_selections)
        j = isempty(available_selections) ? get(last_selections, 1, 1) : rand(available_selections)
        j > length(selection) && (j = 1)
        selection[j] = get(available, i, "")
        
        push!(last_images, i)
        push!(last_selections, j)
        while length(last_images) > 10
            popfirst!(last_images)
        end
        while length(last_selections) > 3
            popfirst!(last_selections)
        end
    end
end 

UI::ParsedHTMLString = cell([
    row(class = "justify-center", h1(class = "q-pa-md", "{{ title }}"))
    toggle("mode", :fitmode, class = "q-ma-md", truevalue = "contain", falsevalue = "cover", style = "position: absolute; right: 0; top: 0; z-index: 1000")

    row(id = "show", cell(col = 1, xs = 12, sm = 6, md = 4, lg = 3, xl = 2, id = R"'s' + i", class = "q-pa-md", @for(i in 1:18),
        htmldiv(class = "relative-position",
            xelem(:transition, name = "q-transition--fade",
                imageview(class = "", src = R"images[selection[i - 1] - 1]", key = R"selection[i - 1]", style = R"'transition: all ' + this.duration + 's ease-in-out;'", img__class = "hh", ratio! = 1, fit = :fitmode)
            )
        )
    ))
])

ui() = UI

@methods Slideshow js"""
updateRaster(){
    const total_height = document.body.clientHeight - document.getElementById('show').getClientRects()[0].top
    const width = document.getElementById('s1').clientWidth
    const height = document.getElementById('s1').clientHeight
    const m = Math.floor(total_height / height)
    const n = Math.round(document.body.clientWidth / width)
    this.raster = [m, n]
}
"""

@mounted Slideshow js"""{
    window.addEventListener("resize", this.updateRaster);
}
"""

@before_destroy Slideshow js"""{
    window.removeEventListener("resize", this.updateRaster);
}
"""


function __init__()
    route("/") do
        global model = ReactiveTools.init_model(Slideshow)
        page(model, ui, class = "window-height overflow-hidden", "v-cloak") |> html
    end
    up(open_browser = true)
end

end 