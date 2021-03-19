using Stipple, StippleUI
import Stipple: opts, OptDict
Stipple.@kwdef mutable struct Example <: ReactiveModel
  name::R{String} = "Stipple!"
  firstname::String = "You"
  name_private::String = "private"
  private::Private{String} = "Don't show"
  readonly::R{String} = "readonly", :readonly
  options::R{OptDict} = opts(f = js"()=>{}"), :jsfunction
  js::R{JSONText} = js"()=>{}", :jsfunction
end

model = Stipple.init(Example())
Stipple.js_watch(Example) = """
  js: function(val) { if (typeof(val)=="function") { val() } }
"""

function ui()
  [
    page(
      vm(model), class="container", title="Hello Stipple",
      [
        h1([
          "Hello, "
          span("", @text(:name))
        ])

        p([
          "What is your name? "
          textfield("", :name, placeholder="type your name", label="Name", outlined="", filled="")
        ])
      ]
    )
  ] |> html
end

route("/", ui)

up(open_browser=true)

model.js[] = js"""() => console.log("Hello")"""
model.js[] = js"""() => console.log("World")"""

model.options[] = opts(f = js"""() => console.log("Let's Stipple!")""")
model.js[] = model.options[][:f]
