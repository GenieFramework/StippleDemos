using Revise
using Stipple, StippleUI, OffsetArrays
import Stipple: opts, OptDict

Stipple.@kwdef mutable struct Example <: ReactiveModel
  name::R{String} = "Stipple!"
  name_::R{String} = "readonly"
  name__::R{String} = "private", PUBLIC
  firstname::String = "You"
  readonly_::String = "readonly"
  privatestring__::String = "private"
  noauto::R{String} = "Don't autoupdate", NO_WATCHER
  no_backend_watcher::R{String} = "No backend watcher", READONLY, NO_BACKEND_WATCHER
  no_frontend_watcher::R{String} = "No frontend watcher", NO_FRONTEND_WATCHER
  private::R{String} = "private", PRIVATE
  readonly::R{String} = "readonly", READONLY
  options::R{OptDict} = opts(f = js"() => {}"), JSFUNCTION
  js::R{JSONText} = js"()=>{}", JSFUNCTION
  header::R{Bool} = true
  darkmode::R{Bool} = true
  array::OffsetArray = OffsetArray([true, false, false], -1)
  rarray::R{OffsetArray} = OffsetArray([true, false, false], -1)
end

css() = Stipple.style("""
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
          row(h1(["Hello, ", span("", @text(:name))]))
        ], v__if=:header)

        row(cell(class="st-module", [
          p(toggle("Camera on", fieldname = :header)),
          p(toggle("Darkmode", :darkmode, disable=:header))
        ]))
        
        row(cell(class="st-module", row([
          cell(class="st-br", [
            p(toggle("array[0]", R"array[0]")),            
            p(toggle("array[1]", R"array[1]")),            
            p(toggle("array[2]", R"array[2]", disable=:header))
          ]),
          cell(class="st-br", [
            p(toggle("rarray[0]", R"rarray[0]")),            
            p(toggle("rarray[1]", R"rarray[1]")),            
            p(toggle("rarray[2]", R"rarray[2]"))
          ])
        ])))

        row(cell(class="st-module", row([
          cell(class="st-br", [
            h1("array")
            p("{{ array }}")
          ])

          cell(class="st-br", [
            h1("rarray")
            p("{{ rarray }}")
          ])
        ])))
        
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

# standard (non-notifying) indexing into Reactive elements
@show model.rarray[][1]
@show model.options[][:f]

model.rarray[][1] = true
model.options[][:hh] = "test"


# new notifying version of setindex!
@show model.rarray[1]
@show model.options[:f]
model.js[] = model.options[:f]

model.rarray[1] = true
model.options[:hh] = "test"

model.array[1] = true

model.array

function togglefun(tf)
  if tf
      @info "true"
  else
      @info "false"
  end
end