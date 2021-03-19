using Stipple, StippleUI
import Stipple: opts, OptDict
Stipple.@kwdef mutable struct Example <: ReactiveModel
  name::R{String} = "Stipple!"
  firstname::String = "You"
  name_private::String = "private"
  private::Private{String} = "Don't show"
  readonly::R{String} = "readonly", :readonly
  options::R{OptDict} = opts(f = js"()=>{}"), :jsfunction
  js::R{JSONText} = js"()=>{}", :readonly
end

model = Stipple.init(Example())

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