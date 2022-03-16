using Stipple, StippleUI
import Stipple.opts

@reactive! mutable struct Test <: ReactiveModel
    s_editor::R{String} = "What you see is <b>what</b> you get."
    myfont::R{Dict{Symbol, Any}} = opts(
        arial = "Arial",
        arial_black = "Arial Black",
        courier_new = "Courier New",
        times_new_roman = "Times New Roman"
    )
    mytoolbar::R{Vector{Vector{Union{Symbol,String}}}} = [
        [:bold, :italic],
        [:customItalic], 
        ["save", "upload"],
        ["spellcheck"],
        ["disabledButton"],
        ["custom_btn"]
    ]
    mydef::R{Dict{Symbol, Any}} = opts(
        bold = opts(cmd = "bold", label = "Bold", icon = nothing, tip = "My bold tooltip"),
        italic = opts(cmd = :italic, icon = "border_color", tip = "My italic tooltip"),
        customItalic = opts(cmd = :italic, icon = :camera_enhance, tip = "Italic"),
        save = opts(
            tip = "Save your work", icon = :save, label = "Save", 
            handler = jsfunction"Test.$q.notify({type: 'positive', message: 'I saved your work!'})"
        ),
        upload = opts(tip = "Upload to cloud", icon = "cloud_upload", label = "Upload",
            handler = jsfunction"Test.upload()"
        ),
        spellcheck = opts(tip = "Run spell-check", icon = "spellcheck"),
        disabledButton = opts(tip = "I am disabled...", disable = true, icon = "cloud_off")
    )
end

Stipple.js_methods(::Test) = raw"""
    upload: function() { this.$q.notify({
        type: 'negative',
        message: 'Error during upload, no destination specified!'
    }) }
"""

function handlers(model)
    on(model.isready) do isready
        isready || return
        @async begin
            sleep(0.2)
            push!(model)
        end
    end

    model
end

model = init(Test, debounce = 0) |> handlers

function ui(model)
    page(model, class = "container", row(cell(class = "st-module", row([
        cell(editor(:s_editor, toolbar = :mytoolbar, definitions = :mydef, font = :myfont,
            max__height = "50vh"
        ))
    ]))), @iif(:isready)) |> html
end

route("/") do 
    global model
    ui(model)
end

up(8020, open_browser=true)