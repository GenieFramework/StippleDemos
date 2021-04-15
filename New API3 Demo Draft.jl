using Revise
using Stipple, StippleUI, OffsetArrays
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
  array::R{OffsetArray} = OffsetArray([true, false, false], -1)
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
Stipple.js_watch(m::Example) = raw"""
  js: function(val) { if (typeof(val)=="function") { val() } },
  darkmode: function(val) { this.$q.dark.set(val) }
"""

Stipple.js_created(m::Example) = raw"""
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
          p(toggle("array[0]", R"array[0]")),            
          p(toggle("array[1]", R"array[1]")),            
          p(toggle("array[2]", R"array[2]")),            
        ]))
        p(h1("Array: {{ array }}"))
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

model.array[1] = true