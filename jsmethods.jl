using Stipple, StippleUI
using Genie.Renderer.Html

Base.@kwdef mutable struct JSmethods <: ReactiveModel
    x::R{Int} = 0 # pressing this will update the array of buttons
end

function restart()
    global model
    model = Stipple.init(JSmethods(), debounce=1)
    on(println, model.x)
end

function ui()

    app = dashboard(vm(model),
        [
         heading("jsmethods"),
         row(cell(class="st-module", [
                                      p(button("Change text", @click("showNotif()"))),
                                     ])),
        ], title = "jsmethods")

    js_methods(app) = """
    showNotif () {
    this.$q.notify({
    message: 'Jim pinged you.',
    color: 'purple'
    })
    }
    """

    html(app)
end


route("/", ui)
Genie.config.server_host = "127.0.0.1"
restart()
up(open_browser = true)

