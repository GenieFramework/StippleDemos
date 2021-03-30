using Revise
using Stipple, StippleUI
import Stipple: opts, OptDict

Stipple.@kwdef mutable struct Example <: ReactiveModel
  name::R{String} = "Stipple!"
  firstname::String = "You"
  name_::String = "readonly"
  name__::String = "private"
  noauto::R{String} = "Don't autoupdate", NO_WATCHER
  no_backend_watcher::R{String} = "No backend watcher", READONLY, NO_BACKEND_WATCHER
  no_frontend_watcher::R{String} = "No frontend watcher", NO_FRONTEND_WATCHER
  private::R{String} = "private", PRIVATE
  readonly::R{String} = "readonly", READONLY
  options::R{OptDict} = opts(f = js"()=>{}"), JSFUNCTION
  js::R{JSONText} = js"()=>{}", JSFUNCTION
  header::R{Bool} = true
  darkmode::R{Bool} = true
end

css() = style("""
:root.stipple-blue body.body--dark{
    --st-dashboard-module: #4e4e4e;
    --st-dashboard-line: #a2a2a2;
    --st-dashboard-bg: #616367;
    --st-slider--track: #aab2b2;
}
.stipple-core body.body--dark{
    --st-dashboard-bg: #616367;
}
""")

model = Stipple.init(Example())
Stipple.js_watch(model) = raw"""
  js: function(val) { if (typeof(val)=="function") { val() } },
  darkmode: function(val) { this.$q.dark.set(val) }
"""

Stipple.js_created(model) = raw"""
  this.$q.dark.set(this.darkmode)
"""

function ui()
  [
    dashboard(
      vm(model), class="container", title="Hello Stipple",
      [
        template([
          h1(["Hello, ", span("", @text(:name))])
        ], v__if=:header)
        row(cell(class="st-module", [
          p(toggle("Camera on", fieldname = :header)),
          p(toggle("Darkmode", :darkmode)),            
        ]))
        p([
          h1("What is your name? ")
          textfield("", :name, placeholder="type your name", label="Name", outlined="", filled="")
        ])
      ]
    )
    css()
  ] |> html
end

route("/", ui)

up(open_browser=true)

model.js[] = js"""() => console.log("Hello")"""
model.js[] = js"""() => console.log("World")"""

model.options[] = opts(f = js"""() => console.log("Let's Stipple!")""")
model.js[] = model.options[][:f]
